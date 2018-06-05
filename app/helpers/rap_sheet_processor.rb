require 'csv'
require 'rap_sheet_parser'

class RapSheetProcessor
  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    input_directory = connection.directories.new(key: Rails.configuration.input_bucket)
    output_directory = connection.directories.new(key: Rails.configuration.output_bucket)

    input_directory.files.each do |input_file|
      begin
        reader = PDF::Reader.new(StringIO.new(input_file.body))
        output_directory.files.create(
          key: input_file.key.gsub('.pdf', '.csv'),
          body: self.generate_output_file_contents(reader),
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

  def self.create_csv(conviction_counts)
    CSV.generate do |csv|
      csv << ['Date', 'Case Number', 'Courthouse', 'Charge', 'Severity', 'Sentence', 'Prop 64 Eligible']
      conviction_counts.each do |count|
        count_data = [
          count.event.date,
          count.event.case_number,
          count.event.courthouse,
          count.code_section,
          count.severity,
          count.event.sentence,
          count.prop64_eligible?
        ]
        csv << count_data
      end
    end
  end

  def self.generate_output_file_contents(reader)
    text = self.get_pdf_text(reader)
    convictions = self.parse_convictions(text)
    eligible_convictions = EligibilityChecker.new(convictions).eligible_events
    self.create_csv(eligible_convictions.flat_map(&:counts))
  end
end
