class FillMisdemeanorPetitions
  def initialize(path:, output_dir:)
    @path = path
    @output_dir = output_dir
  end

  def fill
    # Row
    # 0 Courtno
    # 1 True Name
    # 2 DOB
    # 3 Conviction Date
    # 4 Sentence Date
    # 5 Case Type  
    # 6 Dispo Code
    # 7 Disposition                       
    # 8 11357(a)
    # 9 11357(b)
    # 10 11357(c)
    # 11 11359
    # 12 11359(a)
    # 13 11359(b)
    # 14 11360(a)
    # 15 11360(b)
    # 16 Other
    # 17 Petition Created
    # 18 Date Petition Drafted
    # 19 Date Petition Submitted
    # 20 Petition Granted
    # 21 Date Sent to PDR
    # 22 Notes
    # 23 Copy Requested
    # 24 Email Address
    # 25 Mailing Address
    # 26 Willing to Speak to Media
    # 27 Phone Number

    CSV.foreach(path, headers: true) do |row|
      case_number = row[0].strip
      name = row[1].strip
      date_of_birth = row[2].strip
      count_11357a = row[8].strip
      count_11357b = row[9].strip
      count_11357c = row[10].strip
      count_11359 = row[11].strip

      other_charges = others(row)

      fields = {
        "last name, first name, middle name (DOB)": "#{name} (DOB #{date_of_birth})",
        "Court Number": case_number,
        "Check Box2": checkbox_val(count_11357a),
        "Check Box3": checkbox_val(count_11357b),
        "Check Box4": checkbox_val(count_11357c),
        "Check Box5": checkbox_val(count_11359),
        "Check Box7": yes(other_charges.present?),
        "PROSECUTING ATTORNEY REQUEST FOR DISMISSAL AND SEALING": other_charges.join(', '),
        "Date": Date.today
      }

      fill_petition(name.gsub('/', '_'), fields)
    end
  end

  private

  attr_reader :path, :output_dir

  def others(row)
    count_11359a = row[12]&.strip
    count_11359b = row[13]&.strip
    count_11360a = row[14]&.strip
    
    [count_11359a, count_11359b, count_11360a].compact.reject do |data|
      data.empty? || data.include?('#N/A')
    end
  end

  def yes(bool)
    "Yes" if bool
  end

  def checkbox_val(data)
    'Yes' unless data.include?('#N/A')
  end

  def fill_petition(name, fields)
    file_name = "#{output_dir}/petition_#{name}.pdf"
    pdftk = PdfForms.new(Cliver.detect('pdftk'))

    pdftk.fill_form 'app/assets/petitions/prop64_misdemeanors.pdf', file_name, fields
  end
end
