require 'rails_helper'

describe EligibilityEstimate do
  it 'populates fields' do
    count = build_court_count(code: 'HS', section: '11357')
    event = build_court_event(
      date: Date.new(2001, 1, 5),
      counts: [count]
    )
    rap_sheet = build_rap_sheet(events: [event])
    rap_sheet_with_eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)
    event_with_eligibility = EventWithEligibility.new(event)
    count_with_eligibility = CountWithEligibility.new(count)

    eligibility_estimate = described_class.build(
      event_with_eligibility: event_with_eligibility,
      count_with_eligibility: count_with_eligibility,
      rap_sheet_with_eligibility: rap_sheet_with_eligibility
    )

    expect(eligibility_estimate.prop_64_eligible).to eq 'yes'
  end
end
