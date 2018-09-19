require 'rails_helper'

describe EventProperties do
  describe '#build_from_eligibility' do
    it 'populates eligibility fields' do
      sentence = RapSheetParser::ConvictionSentence.new(probation: 1.year)
      disposition = build_disposition(type: 'convicted', severity: 'F', sentence: sentence)

      event = build_court_event(
        date: Date.new(2001, 1, 5),
        counts: [
          build_count(code: 'PC', section: '456'),
          build_count(code: 'PC', section: '789', disposition: disposition)
        ]
      )
      rap_sheet = build_rap_sheet(
        events: [event, build_arrest_event(date: Date.new(2001, 11, 4))]
      )
      event_properties = described_class.build(event: event, rap_sheet: rap_sheet)

      expect(event_properties.has_felonies).to eq true
      expect(event_properties.has_probation).to eq true
      expect(event_properties.has_prison).to eq false
      expect(event_properties.has_probation_violations).to eq true
      expect(event_properties.dismissed_by_pc1203).to eq false
    end
  end
end
