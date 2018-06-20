require 'csv'
require 'rap_sheet_parser'

class RapSheetProcessor
  def initialize
    @summary_csv = SummaryCSV.new
    @summary_errors = ''
  end

  def run
    input_directory.files.to_a.sort_by { |f| f.key }.each do |input_file|
      process_one_rap_sheet(input_file)
    end

    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')

    save_summary_csv(timestamp)
    save_summary_errors(timestamp)
  end

  private

  attr_accessor :summary_csv, :summary_errors

  def process_one_rap_sheet(input_file)
    eligibility = rap_sheet_with_eligibility(input_file)

    summary_csv.append(input_file.key, eligibility)

    # Upload CSV for this rap sheet to Amazon
    output_directory.files.create(
      key: input_file.key.gsub('.pdf', '.csv'),
      body: SingleCSV.new(eligibility).text,
      content_type: 'text/csv'
    )

    input_file.destroy
  rescue => e
    output_directory.files.create(
      key: input_file.key.gsub('.pdf', '.error'),
      body: e.message
    )
    summary_errors << "#{input_file.key}:\n#{e.message}\n\n"
  end

  def save_summary_errors(timestamp)
    unless summary_errors.blank?
      output_directory.files.create(
        key: "summary_#{timestamp}.error",
        body: summary_errors
      )
    end
  end

  def save_summary_csv(timestamp)
    output_directory.files.create(
      key: "summary_#{timestamp}.csv",
      body: summary_csv.text,
      content_type: 'text/csv'
    )
  end

  def input_directory
    @input_directory ||= connection.directories.new(key: Rails.configuration.input_bucket)
  end

  def output_directory
    @output_directory ||= connection.directories.new(key: Rails.configuration.output_bucket)
  end

  def connection
    @connection ||= Fog::Storage.new(Rails.configuration.fog_params)
  end

  def rap_sheet_with_eligibility(input_file)
    text = PDFReader.new(input_file.body).text
    rap_sheet = RapSheetParser::Parser.new.parse(text)

    RapSheetWithEligibility.new(rap_sheet)
  end
end
