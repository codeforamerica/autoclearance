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
        "MCN" => event.case_number,
        "FOR RESENTENCING OR DISMISSAL HS  113618b" => on_or_off(event.remedy == 'resentencing'),
        "FOR REDESIGNATION OR DISMISSALSEALING HS  113618f" => on_or_off(event.remedy == 'redesignation'),
        "11357  Possession of Marijuana" => on_or_off(counts_contain_code "HS 11357"),
        "11358  Cultivation of Marijuana" => on_or_off(counts_contain_code "HS 11358"),
        "11359  Possession of Marijuana for Sale" => on_or_off(counts_contain_code "HS 11359"),
        "11360  Transportation Distribution or" => on_or_off(counts_contain_code "HS 11360"),
    }

    tempfile
  end

  private

  def counts_contain_code(code)
    counts.any? { |count| count.code_section_starts_with([code]) }
  end

  def on_or_off(bool)
    bool ? 'On' : 'Off'
  end

  attr_reader :counts, :event, :eligibility
end