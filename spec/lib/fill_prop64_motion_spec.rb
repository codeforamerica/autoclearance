require 'rails_helper'

RSpec.describe FillProp64Motion do
  it 'fills out fields' do
    counts = [
        build_court_count(code: 'HS', section: '11357'),
        build_court_count(code: 'HS', section: '11359')
    ]
    event = build_conviction_event(
        name_code: '03',
        case_number: 'MYCASE01',
        date: Date.new(1994, 1, 2),
        sentence: RapSheetParser::ConvictionSentence.new(probation: 1.year),
        counts: counts
    )
    personal_info = build_personal_info(names: {'03' => 'SINGLETON, SYMONNE'})
    eligibility = RapSheetWithEligibility.new(build_rap_sheet(events: [event], personal_info: personal_info))
    event_with_eligibility = EventWithEligibility.new(event)

    file = described_class.new(counts, event_with_eligibility, eligibility).filled_motion
    fields = get_fields_from_pdf(file)

    expect(fields["Defendant"]).to eq "SINGLETON, SYMONNE"
    expect(fields["SCN"]).to eq "MYCASE01"
    expect(fields["MCN"]).to eq "MYCASE01"
    expect(fields["FOR RESENTENCING OR DISMISSAL HS  113618b"]).to eq 'Off'
    expect(fields["FOR REDESIGNATION OR DISMISSALSEALING HS  113618f"]).to eq 'On'
    expect(fields["11357  Possession of Marijuana"]).to eq('On')
    expect(fields["11358  Cultivation of Marijuana"]).to eq('Off')
    expect(fields["11359  Possession of Marijuana for Sale"]).to eq('On')
    expect(fields["11360  Transportation Distribution or"]).to eq('Off')
  end
end