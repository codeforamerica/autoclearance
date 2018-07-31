class RapSheetDeidentifier
  def initialize
    @connection = Fog::Storage.new(Rails.configuration.fog_params)
    @input_directory = @connection.directories.new(key: Rails.configuration.input_bucket)
    @output_directory = @connection.directories.new(key: Rails.configuration.output_bucket)
  end

  def run
    @input_directory.files.to_a.sort_by { |f| f.key }.each do |input_file|
      text = PDFReader.new(input_file.body).text
      id = Digest::MD5.hexdigest(text)
      deidentified_text = deidentify(text)
      @output_directory.files.create(
        key: "redacted_rap_sheet_#{id}.txt",
        body: deidentified_text
      )
    end
  end

  def deidentify(text)
    t = remove_personal_info_section(text)
    t = randomize_dob(t)
    randomize_case_numbers(t)
  end

  def randomize_dob(text)
    dob_offset_days = rand(3600) - 1800
    dob_regex = /DOB[:\/](\d{8})/
    matches = text.scan(dob_regex)
    matches.uniq.each do |m|
      date_string = m[0]
      date = Date.parse(date_string, 'YYYYMMDD')
      new_date = date + dob_offset_days.days
      new_date_string = new_date.strftime('%Y%m%d')
      text = text.gsub(date_string, new_date_string)
    end
    text
  end

  def randomize_case_numbers(text)
    case_number_regex = /#(.+)$/
    matches = text.scan(case_number_regex)
    matches.uniq.each do |m|
      case_number_string = m[0]
      chars = case_number_string.chars
      chars.each_with_index do |c, i|
        if c.match(/\d/)
          digit = c.to_i
          digit = (digit + rand(10)) % 10
          chars[i] = digit
        end
      end
      new_case_number = chars.join
      text = text.gsub(case_number_string, new_case_number)
    end
    text
  end

  def remove_personal_info_section(text)
    slice_index = text.index(/^\s*(\*\s?){4}$/)
    text.slice!(0..(slice_index - 1))
    text
  end
end
