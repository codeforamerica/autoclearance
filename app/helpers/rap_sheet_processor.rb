require 'csv'
require 'rap_sheet_parser'

class RapSheetProcessor
  def initialize(county)
    @county = county
    @summary_csv = SummaryCSV.new
    @summary_errors = ''
    @warning_log = StringIO.new
    @num_motions = 0
    @rap_sheets_processed = 0
  end

  def run
    start_time = Time.zone.now
    initial_rap_sheet_count = AnonRapSheet.count

    input_directory.files.to_a.sort_by(&:key).each do |input_file|
      process_one_rap_sheet(input_file)
    end

    timestamp = start_time.strftime('%Y%m%d-%H%M%S')
    save_summary_csv(timestamp)
    save_summary_errors(timestamp)
    save_summary_warnings(timestamp)

    time = (Time.zone.now - start_time)

    # rubocop:disable Rails/Output
    puts "#{@rap_sheets_processed} RAP #{'sheet'.pluralize(@rap_sheets_processed)} " \
         "produced #{@num_motions} #{'motion'.pluralize(@num_motions)} " \
         "in #{time} seconds"

    new_rap_sheets = AnonRapSheet.count - initial_rap_sheet_count
    existing_rap_sheets = @rap_sheets_processed - new_rap_sheets
    puts "Added #{new_rap_sheets} RAP #{'sheet'.pluralize(new_rap_sheets)} to analysis db. " \
         "Overwrote #{existing_rap_sheets} existing RAP #{'sheet'.pluralize(existing_rap_sheets)}."
    # rubocop:enable Rails/Output
  end

  private

  attr_accessor :summary_csv, :summary_errors

  def process_one_rap_sheet(input_file)
    warning_logger = Logger.new(
      @warning_log,
      formatter: proc { |_severity, _datetime, _progname, msg| "[#{input_file.key}] #{msg}\n" }
    )

    eligibility = rap_sheet_with_eligibility(input_file, warning_logger)

    unless eligibility.potentially_eligible_counts?
      input_file.destroy
      return
    end

    summary_csv.append(input_file.key, eligibility)

    # Create a bunch of PDFs
    eligibility
      .eligible_events
      .select { |event| event.eligible_counts.any? }
      .each_with_index do |event, index|
      file_name = "#{input_file.key.gsub('.pdf', '')}_motion_#{index}.pdf"
      eligible_counts = event.eligible_counts

      @num_motions += 1
      output_directory.files.create(
        key: file_name,
        body: FillProp64Motion.new(eligible_counts, event, eligibility.personal_info).filled_motion,
        content_type: 'application/pdf'
      )
    end
    input_file.destroy
  rescue Rails.configuration.logged_exceptions => e
    error = ([e.message] + e.backtrace).join("\n")
    output_directory.files.create(
      key: input_file.key.gsub('.pdf', '.error'),
      body: error
    )
    summary_errors << "#{input_file.key}:\n#{error}\n\n"
  end

  def save_summary_errors(timestamp)
    return if summary_errors.blank?

    output_directory.files.create(
      key: "summary_#{timestamp}.error",
      body: summary_errors
    )
  end

  def save_summary_warnings(timestamp)
    return if @warning_log.string.blank?

    output_directory.files.create(
      key: "summary_#{timestamp}.warning",
      body: @warning_log.string
    )
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

    @rap_sheets_processed += 1

    AnonRapSheet.create_or_update(
      text: text,
      county: @county[:name],
      rap_sheet: rap_sheet
    )

    RapSheetWithEligibility.new(
      rap_sheet: rap_sheet,
      county: @county,
      logger: logger
    )
  end
end
