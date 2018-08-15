require 'rails_helper'

describe AnonCycle do
  describe '#build_from_parser' do
    it 'creates AnonCycles and AnonEvents from parser output' do
      event_1 = build_court_event(
        date: Date.new(1999, 1, 5),
        courthouse: 'Some courthouse',
      )

      event_2 = build_court_event(
        date: Date.new(1991, 3, 14),
        courthouse: 'CASC San Francisco',
      )

      cycle = RapSheetParser::Cycle.new(events: [event_1, event_2])

      anon_cycle = described_class.build_from_parser(cycle)
      expect(anon_cycle.anon_events.length).to eq 2

      events = anon_cycle.anon_events
      expect([events[0].agency, events[1].agency]).to contain_exactly('CASC San Francisco', 'Some courthouse')
    end

    it 'it only saves conviction and arrest events' do
      conviction_court_event = build_court_event(
        date: Date.new(1999, 1, 5),
        courthouse: 'Some courthouse',
      )

      arrest_event = build_arrest_event(
        date: Date.new(1991, 3, 14),
        agency: 'arrest agency'
      )

      dismissed_court_event = build_court_event(
        date: Date.new(1995, 2, 10),
        courthouse: 'Some other courthouse',
        counts: [build_court_count(disposition_type: 'dismissed')]
      )

      cycle = RapSheetParser::Cycle.new(events: [arrest_event, conviction_court_event, dismissed_court_event])

      anon_cycle = described_class.build_from_parser(cycle)

      events = anon_cycle.anon_events
      expect(events.length).to eq 2

      expect(events[0].agency).to eq 'arrest agency'
      expect(events[0].date).to eq Date.new(1991, 3, 14)
      expect(events[0].event_type).to eq 'arrest'
      
      expect(events[1].agency).to eq 'Some courthouse'
      expect(events[1].date).to eq Date.new(1999, 1, 5)
      expect(events[1].event_type).to eq 'court'
    end
  end
end
