require 'rails_helper'

describe AnonCycle do
  describe '#create_from_parser' do
    it 'creates AnonCycles and AnonEvents from parser output' do
      anon_rap_sheet = AnonRapSheet.create!(county: 'san_francisco', checksum: Digest::SHA2.new.digest('foo'))

      event_1 = build_court_event(
        date: Date.new(1999, 1, 5),
        courthouse: 'Some courthouse',
        )

      event_2 = build_court_event(
        date: Date.new(1991, 3, 14),
        courthouse: 'CASC San Francisco',
        )

      cycle = RapSheetParser::Cycle.new(events: [event_1, event_2])

      described_class.create_from_parser(cycle, anon_rap_sheet: anon_rap_sheet)

      expect(AnonCycle.count).to eq 1
      expect(AnonEvent.count).to eq 2

      expect(AnonCycle.first.anon_rap_sheet).to eq anon_rap_sheet
      events = AnonCycle.first.anon_events
      expect(events[0].agency).to eq 'CASC San Francisco'
      expect(events[1].agency).to eq 'Some courthouse'
    end

    it 'it only saves conviction events' do
      anon_rap_sheet = AnonRapSheet.create!(county: 'san_francisco', checksum: Digest::SHA2.new.digest('foo'))

      conviction_court_event = build_court_event(
        date: Date.new(1999, 1, 5),
        courthouse: 'Some courthouse',
        )

      arrest_event = build_arrest_event(
        date: Date.new(1991, 3, 14),
        )

      dismissed_court_event = build_court_event(
        date: Date.new(1995, 2, 10),
        courthouse: 'Some other courthouse',
        counts: [build_court_count(disposition_type: 'dismissed')]
        )

      cycle = RapSheetParser::Cycle.new(events: [conviction_court_event, arrest_event, dismissed_court_event])

      described_class.create_from_parser(cycle, anon_rap_sheet: anon_rap_sheet)

      expect(AnonEvent.count).to eq 1

      events = AnonCycle.first.anon_events
      expect(events[0].agency).to eq 'Some courthouse'
      expect(events[0].date).to eq Date.new(1999, 1, 5)
    end
  end
end
