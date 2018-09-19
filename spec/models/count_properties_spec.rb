require 'rails_helper'

describe CountProperties do
  describe '#build' do
    it 'populates eligibility fields for prop 64 code sections' do
      count = build_count(code: 'HS', section: '11357')

      event = build_court_event(
        date: Date.new(2001, 1, 5),
        counts: [count]
      )

      count_properties = described_class.build(
        count: count,
        rap_sheet: build_rap_sheet(events: [event]),
        event: event
      )

      expect(count_properties.has_prop_64_code).to eq true
      expect(count_properties.has_two_prop_64_priors).to eq false
      expect(count_properties.prop_64_plea_bargain).to eq 'no'
      expect(count_properties.eligibility_estimate.prop_64_eligible).to eq 'yes'
    end

    it 'populates eligibility fields for plea bargained counts' do
      arrest_count = build_count(code: 'HS', section: '11358')
      bargain_count = build_count(code: 'PC', section: '32')

      arrest_event = build_arrest_event(date: Date.new(2001, 11, 4), counts: [arrest_count])
      bargain_event = build_court_event(
        date: Date.new(2001, 1, 5),
        counts: [bargain_count]
      )

      count_properties = described_class.build(
        count: bargain_count,
        rap_sheet: build_rap_sheet(events: [arrest_event, bargain_event]),
        event: bargain_event
      )

      expect(count_properties.has_prop_64_code).to eq false
      expect(count_properties.has_two_prop_64_priors).to eq false
      expect(count_properties.prop_64_plea_bargain).to eq 'yes'
    end

    it 'populates eligibility fields for prop 64 code sections with two priors' do
      count_1 = build_count(code: 'HS', section: '11358')
      count_2 = build_count(code: 'HS', section: '11358')
      count_3 = build_count(code: 'HS', section: '11358')

      event_1 = build_court_event(
        date: Date.new(2001, 1, 5),
        counts: [count_1]
      )
      event_2 = build_court_event(
        date: Date.new(2002, 2, 5),
        counts: [count_2]
      )
      event_3 = build_court_event(
        date: Date.new(2003, 3, 5),
        counts: [count_3]
      )

      count_properties = described_class.build(
        count: count_3,
        rap_sheet: build_rap_sheet(events: [event_1, event_2, event_3]),
        event: event_3
      )

      expect(count_properties.has_prop_64_code).to eq true
      expect(count_properties.has_two_prop_64_priors).to eq true
      expect(count_properties.prop_64_plea_bargain).to eq 'no'
    end
  end
end
