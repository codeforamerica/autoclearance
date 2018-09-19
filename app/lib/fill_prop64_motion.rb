class FillProp64Motion
  def initialize(counts, event, personal_info)
    @counts = counts
    @event = event
    @personal_info = personal_info
  end

  def filled_motion
    tempfile = Tempfile.new

    pdftk = PdfForms.new(Cliver.detect('pdftk'))

    pdftk.fill_form 'app/assets/motions/prop64.pdf', tempfile.path,
                    "Defendant" => name,
                    "SCN" => event.case_number,
                    "FOR RESENTENCING OR DISMISSAL HS  113618b" => on_or_off(event.remedy == 'resentencing'),
                    "FOR REDESIGNATION OR DISMISSALSEALING HS  113618f" => on_or_off(event.remedy == 'redesignation'),
                    "11357  Possession of Marijuana" => on_or_off(number_of_counts_for_code("HS 11357") > 0),
                    "11358  Cultivation of Marijuana" => on_or_off(number_of_counts_for_code("HS 11358") > 0),
                    "11359  Possession of Marijuana for Sale" => on_or_off(number_of_counts_for_code("HS 11359") > 0),
                    "11360  Transportation Distribution or" => on_or_off(number_of_counts_for_code("HS 11360") > 0),
                    "11357 Count" => count_multiplier("HS 11357"),
                    "11358 Count" => count_multiplier("HS 11358"),
                    "11359 Count" => count_multiplier("HS 11359"),
                    "11360 Count" => count_multiplier("HS 11360"),
                    "Other Health and Safety Code Section" => on_or_off(other_code_sections.any?),
                    "Text2" => other_code_sections.join(', '),
                    "The District Attorney finds that defendant is eligible for relief and now requests the court to recall and resentence" => "On"

    tempfile
  end

  private

  def other_code_sections
    code_sections = counts.reject do |count|
      count.subsection_of?(["HS 11357", "HS 11358", "HS 11359", "HS 11360"])
    end.map(&:code_section)

    code_sections.uniq.map do |code|
      count = code_sections.count(code)

      (count == 1) ? code : "#{code} x#{count}"
    end
  end

  def name
    return unless personal_info

    first_name_key = personal_info.names.keys.min_by(&:to_i)
    if first_name_key != event.name_code
      "#{personal_info.names[first_name_key]} AKA #{personal_info.names[event.name_code]}"
    else
      personal_info.names[first_name_key]
    end
  end

  def number_of_counts_for_code(code)
    counts.select { |count| count.subsection_of?([code]) }.length
  end

  def count_multiplier(code)
    counts = number_of_counts_for_code(code)
    counts > 1 ? "x#{counts}" : ""
  end

  def on_or_off(bool)
    bool ? 'On' : 'Off'
  end

  attr_reader :counts, :event, :personal_info
end
