class RapSheetDeidentifier
  def initialize
    @connection = Fog::Storage.new(Rails.configuration.fog_params)
    @input_directory = @connection.directories.new(key: Rails.configuration.input_bucket)
    @output_directory = @connection.directories.new(key: Rails.configuration.output_bucket)
  end

  def run
    @input_directory.files.to_a.sort_by(&:key).each do |input_file|
      text = PDFReader.new(input_file.body).text
      next unless first_cycle_delimiter_index(text)

      id = Digest::MD5.hexdigest(text)
      deidentified_text = deidentify(text)
      @output_directory.files.create(
        key: "redacted_rap_sheet_#{id}.txt",
        body: deidentified_text
      )

      @output_directory.files.create(
        key: "redacted_rap_sheet_#{id}.pdf",
        body: pdf_contents(deidentified_text)
      )
    end
  end

  private

  def pdf_contents(text)
    tmp_text = Tempfile.new
    tmp_text.write(text)
    tmp_text.close

    tmp_pdf = Tempfile.new
    `enscript -B #{tmp_text.path} -q -o - | ps2pdf -q - #{tmp_pdf.path}`

    tmp_pdf.read
  end

  def deidentify(text)
    t = remove_personal_info_section(text)
    t = randomize_dob(t)
    randomize_case_numbers(t)
  end

  def randomize_dob(text)
    dob_regex = %r{DOB[:\/](\d{8})}
    matches = text.scan(dob_regex)
    matches.uniq.each do |m|
      date_string = m[0]
      text = text.gsub(date_string, random_date)
    end
    text
  end

  def random_date
    Time.zone.at(rand * Time.zone.now.to_i).strftime('%Y%m%d')
  end

  def randomize_case_numbers(text)
    case_number_regex = /#(.+)$/
    matches = text.scan(case_number_regex)
    matches.uniq.each do |m|
      case_number_string = m[0]
      chars = case_number_string.chars
      chars.each_with_index do |c, i|
        next unless /\d/.match?(c)

        digit = c.to_i
        digit = (digit + rand(10)) % 10
        chars[i] = digit
      end
      new_case_number = chars.join
      text = text.gsub(case_number_string, new_case_number)
    end
    text
  end

  def remove_personal_info_section(text)
    text.slice!(0..(first_cycle_delimiter_index(text) - 1))
    text.prepend(fake_personal_info)
  end

  def first_cycle_delimiter_index(text)
    text.index(/^(\s| )*(\*(\s| )?){4}$/)
  end
end

def fake_personal_info
  <<~TEXT
    FROM: CLET   ISN: 00003 DATE: 02/05/01 TIME: 09:36:27 RESP MSG
    TO:   CT032474  OSN: 00003 DATE: 05/15/12 TIME: 09:36:30
    USERID: OBI_WAN

    IH

    RE: QHY.CA0313113A.10243565.PM,PM,P      DATE:20010205 TIME:09:36:26
    RESTRICTED-DO NOT USE FOR EMPLOYMENT,LICENSING OR CERTIFICATION PURPOSES
    ATTN:PM,PM,P,O,1954249,

    ************************************************************************
    FOR CALIFORNIA AGENCIES ONLY - HAS PREVIOUS QUALIFYING OFFENSE. COLLECT DNA IF INCARCERATED, CONFINED, OR ON PROBATION OR PAROLE FOLLOWING ANY MISDEMEANOR OR FELONY CONVICTION. REQUEST KITS AND INFO AT (510) 310- 3000 OR PC296.PC296@DOJ.CA.GOV.
    ************************************************************************

    ** III MULTIPLE SOURCE RECORD

    CII/A01234557
    DOB/19681122    SEX/M  RAC/WHITE
    HGT/511  WGT/265  EYE/BLU  HAI/BRO  POB/CA
    NAM/01 LAST, FIRST
    02 NAME, BOB
    FBI/7778889LA2
    CDL/C45667234 C14546456
    SOC/549377146
    OCC/CONCRET
  TEXT
end
