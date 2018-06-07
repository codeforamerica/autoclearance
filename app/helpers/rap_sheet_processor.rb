require 'csv'
require 'rap_sheet_parser'

class RapSheetProcessor
  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    input_directory = connection.directories.new(key: Rails.configuration.input_bucket)
    output_directory = connection.directories.new(key: Rails.configuration.output_bucket)
    summary_csv = SummaryCSV.new
    summary_errors = ''
    
    input_directory.files.to_a.sort_by {|f| f.key}.each do |input_file|
      begin
        text = PDFReader.new(input_file.body).text
        counts = self.get_counts_with_eligibility(text)
        summary_csv.append(input_file.key, counts)
        output_directory.files.create(
          key: input_file.key.gsub('.pdf', '.csv'),
          body: SingleCSV.new(counts).text,
          content_type: 'text/csv'
        )
        input_file.destroy
      rescue => e
        output_directory.files.create(
          key: input_file.key.gsub('.pdf', '.error'),
          body: e.message
        )
        summary_errors += "#{input_file.key}:\n"
        summary_errors += "#{e.message}\n\n"
      end
    end

    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
    output_directory.files.create(
      key: "summary_#{timestamp}.csv",
      body: summary_csv.text,
      content_type: 'text/csv'
    )

    unless summary_errors.blank?
      output_directory.files.create(
        key: "summary_#{timestamp}.error",
        body: summary_errors
      )
    end
  end

  def self.get_counts_with_eligibility(text)
    convictions = self.parse_convictions(text)
    eligible_convictions = EligibilityChecker.new(convictions).eligible_events
    eligible_convictions.flat_map(&:counts)
  end

  def self.parse_convictions(text)
    parsed_tree = RapSheetParser::Parser.new.parse(text)
    events = RapSheetParser::EventCollectionBuilder.build(parsed_tree)
    events.with_convictions
  end
end
