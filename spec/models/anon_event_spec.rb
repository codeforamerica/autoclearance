require 'rails_helper'

describe AnonEvent do
  describe '#build_from_parser' do
    it 'creates court event and event properties from parser output' do
      event = build_court_event(
        date: Date.new(1991, 1, 5),
        courthouse: 'Some courthouse',
        counts: [
          build_count(code: 'PC', section: '456'),
          build_count(code: 'PC', section: '789')
        ],
        name_code: nil
      )
      rap_sheet = build_rap_sheet(events: [event])

      anon_event = described_class.build_from_parser(event: event, rap_sheet: rap_sheet)
      expect(anon_event.agency).to eq 'Some courthouse'
      expect(anon_event.event_type).to eq 'court'
      expect(anon_event.date).to eq Date.new(1991, 1, 5)

      event_properties = anon_event.event_properties
      expect(event_properties.has_felonies).to eq false

      counts = anon_event.anon_counts
      expect(counts[0].code).to eq 'PC'
      expect(counts[0].section).to eq '456'
      expect(counts[0].count_number).to eq 1
      expect(counts[1].code).to eq 'PC'
      expect(counts[1].section).to eq '789'
      expect(counts[1].count_number).to eq 2
    end

    it 'only creates event properties if court event has convictions' do
      event = build_court_event(
        counts: [
          build_count(disposition: build_disposition(type: 'dismissed'))
        ]
      )
      rap_sheet = build_rap_sheet(events: [event])
      anon_event = described_class.build_from_parser(event: event, rap_sheet: rap_sheet)
      expect(anon_event.event_properties).to be_nil
    end

    it 'creates arrest event from parser output' do
      count = build_count(
        code: 'PC',
        section: '456'
      )

      event = build_arrest_event(
        date: Date.new(1991, 1, 5),
        agency: 'Some arrest agency',
        counts: [count]
      )
      rap_sheet = build_rap_sheet(events: [event])

      anon_event = described_class.build_from_parser(event: event, rap_sheet: rap_sheet)
      expect(anon_event.agency).to eq 'Some arrest agency'
      expect(anon_event.event_type).to eq 'arrest'
      expect(anon_event.date).to eq Date.new(1991, 1, 5)

      expect(anon_event.event_properties).to be_nil

      count = anon_event.anon_counts[0]
      expect(count.code).to eq 'PC'
      expect(count.section).to eq '456'
      expect(count.count_number).to eq 1
    end
  end
end
