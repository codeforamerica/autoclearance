require 'csv'
require 'rap_sheet_parser'

class RapSheetProcessor
  CSV_HEADER = [
    'Date',
    'Case Number',
    'Courthouse',
    'Charge',
    'Severity',
    'Sentence',
    'Prop 64 Eligible',
    'Needs info under 18',
    'Needs info under 21',
    'Needs info across state lines'
  ]

  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    input_directory = connection.directories.new(key: Rails.configuration.input_bucket)
    output_directory = connection.directories.new(key: Rails.configuration.output_bucket)
    summary_csv = SummaryCSV.new
    
    input_directory.files.to_a.sort_by {|f| f.key}.each do |input_file|
      begin
        reader = PDF::Reader.new(StringIO.new(input_file.body))
        counts = self.get_counts_with_eligibility(reader)
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
      end
    end

    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
    output_directory.files.create(
      key: "summary_#{timestamp}.csv",
      body: summary_csv.text,
      content_type: 'text/csv'
    )
  end

  def self.append_rows_to_summary(summary_rows, filename, rows)
    rows.each do |row|
      summary_rows << [filename] + row
    end
  end

  def self.get_counts_with_eligibility(reader)
    text = self.get_pdf_text(reader)
    convictions = self.parse_convictions(text)
    eligible_convictions = EligibilityChecker.new(convictions).eligible_events
    eligible_convictions.flat_map(&:counts)
  end

  def self.get_pdf_text reader
    reader.pages.map do |page|
      self.strip_page_header_and_footer(page.text)
    end.join()
  end

  def self.strip_page_header_and_footer page_text
    lines = page_text.split("\n")
    lines.pop while lines.last.blank? || lines.last.lstrip.starts_with?('http://', 'https://', 'file://', 'ﬁle://')
    lines.shift while lines.first.blank? || lines.first.lstrip.starts_with?('Page', 'Route')
    lines.join("\n") + "\n"
  end

  def self.parse_convictions(text)
    parsed_tree = RapSheetParser::Parser.new.parse(text)
    events = RapSheetParser::EventCollectionBuilder.build(parsed_tree)
    events.with_convictions
  end

  def self.create_csv(header, rows)
    CSV.generate do |csv|
      csv << header
      rows.each do |row|
        csv << row
      end
    end
  end
end
