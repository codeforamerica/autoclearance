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
      name = row[1].strip
      fields = {
        "last name, first name, middle name (DOB)": "#{name} (DOB #{row[2]})",
        "Court Number": row[0],
        "Check Box2": checkbox_val(row[8]),
        "Check Box3": checkbox_val(row[9]),
        "Check Box4": checkbox_val(row[10]),
        "Check Box5": checkbox_val(row[11]),
        "Date": Date.today
      }

      fill_petition(name.gsub('/','_'), fields)
    end
  end

  private

  attr_reader :path, :output_dir

  def checkbox_val(data)
    'Yes' unless data.include?('#N/A')
  end
  
  def fill_petition(name, fields)
    file_name = "#{output_dir}/petition_#{name}.pdf"
    pdftk = PdfForms.new(Cliver.detect('pdftk'))

    pdftk.fill_form 'app/assets/petitions/prop64_misdemeanors.pdf', file_name, fields
  end
end
