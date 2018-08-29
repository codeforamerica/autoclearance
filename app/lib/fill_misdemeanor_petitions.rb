require 'csv'

class FillMisdemeanorPetitions
  def initialize(path:, output_dir:)
    @path = path
    @output_dir = output_dir
  end

  def fill
    # Row
    # 0 Courtno
    # 1 SFNO
    # 2 True Name
    # 3 DOB
    # 4 Conviction Date
    # 5 Sentence Date
    # 6 Case Type
    # 7 Dispo Code
    # 8 Disposition
    # 9 11357(a)
    # 10 11357(b)
    # 11 11357(c)
    # 12 11359
    # 13 11359(a)
    # 14 11359(b)
    # 15 11360(a)
    # 16 11360(b)
    # 17 Other
    # 18 Petition Created
    # 19 Date Petition Drafted
    # 20 Date Petition Submitted
    # 21 Petition Granted
    # 22 Date Sent to PDR
    # 23 Notes
    # 24 Copy Requested
    # 25 Email Address
    # 26 Mailing Address
    # 27 Willing to Speak to Media
    # 28 Phone Number

    Dir.mkdir("#{output_dir}/with_sf_number") unless File.exists?("#{output_dir}/with_sf_number")
    Dir.mkdir("#{output_dir}/no_sf_number") unless File.exists?("#{output_dir}/no_sf_number")

    CSV.foreach(path, headers: true, encoding: 'ISO-8859-1') do |row|
      court_number = row[0].strip
      name = row[2].strip
      date_of_birth = row[3].strip
      count_11357a = row[9].strip
      count_11357b = row[10].strip
      count_11357c = row[11].strip

      other_charges = others(row)

      fields = {
        "defendant": "#{name} (DOB #{date_of_birth})",
        "sf_number": sf_number(row),
        "court_number": court_number,
        "11357a": checkbox_val(count_11357a),
        "11357b": checkbox_val(count_11357b),
        "11357c": checkbox_val(count_11357c),
        "11360b": "No", # ignored right now since column always empty
        "others": yes(other_charges.present?),
        "other_charges_description": other_charges.join(', '),
        "date": Date.today
      }

      fill_petition("#{name.tr('/', '_')}_#{court_number}", sf_number(row), fields)
    end
  end

  private

  attr_reader :path, :output_dir

  def sf_number(row)
    value = row[1].strip

    value unless value == "0"
  end

  def others(row)
    count_11359 = row[12]&.strip
    count_11359a = row[13]&.strip
    count_11359b = row[14]&.strip
    count_11360a = row[15]&.strip

    [count_11359, count_11359a, count_11359b, count_11360a].compact.reject do |data|
      data.empty? || data.include?('#N/A')
    end
  end

  def yes(bool)
    bool ? "Yes" : "No"
  end

  def checkbox_val(data)
    data.include?('#N/A') ? "No" : "Yes"
  end

  def fill_petition(name, sf_number, fields)
    sub_directory = sf_number ? "with_sf_number" : "no_sf_number"
    file_name = "#{output_dir}/#{sub_directory}/petition_#{name}.pdf"
    pdftk = PdfForms.new(Cliver.detect('pdftk'))
    pdftk.fill_form 'app/assets/petitions/prop64_misdemeanors.pdf', file_name, fields
  end
end
