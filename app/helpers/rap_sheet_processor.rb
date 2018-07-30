require 'csv'
require 'rap_sheet_parser'

class RapSheetProcessor
  def initialize
    @summary_csv = SummaryCSV.new

    @summary_errors = ''

    @warning_log = StringIO.new
  end

  def run
    input_directory.files.to_a.sort_by { |f| f.key }.each do |input_file|
      process_one_rap_sheet(input_file)
    end

    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')

    save_summary_csv(timestamp)
    save_summary_errors(timestamp)
    save_summary_warnings(timestamp)
  end

  private

  attr_accessor :summary_csv, :summary_errors

  def process_one_rap_sheet(input_file)
    warning_logger = Logger.new(
      @warning_log,
      formatter: proc { |severity, datetime, progname, msg| "[#{input_file.key}] #{msg}\n" }
    )

    eligibility = rap_sheet_with_eligibility(input_file, warning_logger)

    unless eligibility.potentially_eligible_counts?
      input_file.destroy
      return
    end

    summary_csv.append(input_file.key, eligibility)

    # Upload CSV for this rap sheet to Amazon
    output_directory.files.create(
      key: input_file.key.gsub('.pdf', '.csv'),
      body: SingleCSV.new(eligibility).text,
      content_type: 'text/csv'
    )

    # Create a bunch of PDFs
    eligibility.eligible_events.select do |event|
      event.counts.any? do |count|
        count.eligible?(event, eligibility)
      end
    end.each_with_index do |event, index|
      file_name = "#{input_file.key.gsub('.pdf', '')}_motion_#{index}.pdf"
      eligible_counts = event.counts.select do |count|
        count.eligible?(event, eligibility)
      end

      output_directory.files.create(
        key: file_name,
        body: FillProp64Motion.new(eligible_counts, event, eligibility).filled_motion,
        content_type: 'application/pdf'
      )
    end
    input_file.destroy
  rescue => e
    error = ([e.message] + e.backtrace).join("\n")
    output_directory.files.create(
      key: input_file.key.gsub('.pdf', '.error'),
      body: error
    )
    summary_errors << "#{input_file.key}:\n#{error}\n\n"
  end

  def save_summary_errors(timestamp)
    unless summary_errors.blank?
      output_directory.files.create(
        key: "summary_#{timestamp}.error",
        body: summary_errors
      )
    end
  end

  def save_summary_warnings(timestamp)
    unless @warning_log.string.blank?
      output_directory.files.create(
        key: "summary_#{timestamp}.warning",
        body: @warning_log.string
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

  def rap_sheet_with_eligibility(input_file, logger)
    text = PDFReader.new(input_file.body).text

    rap_sheet = RapSheetParser::Parser.new.parse(text, logger: logger)

    RapSheetWithEligibility.new(rap_sheet, logger: logger)
  end
end
