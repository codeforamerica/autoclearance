class FillProp64Motion
  def initialize(counts, event, eligibility)
    @counts = counts
    @event = event
    @eligibility = eligibility
  end

  def filled_motion
    tempfile = Tempfile.new

    pdftk = PdfForms.new(Cliver.detect('pdftk'))

    pdftk.fill_form 'app/assets/motions/prop64.pdf', tempfile.path, {
      "Defendant" => eligibility.personal_info.names[event.name_code],
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
      "11360 Count" => count_multiplier("HS 11360")
    }

    tempfile
  end

  private

  def number_of_counts_for_code(code)
    counts.select { |count| count.code_section_starts_with([code]) }.length
  end

  def count_multiplier(code)
    counts = number_of_counts_for_code(code)
    counts > 1 ? "x#{counts}" : ""
  end

  def on_or_off(bool)
    bool ? 'On' : 'Off'
  end

  attr_reader :counts, :event, :eligibility
end
