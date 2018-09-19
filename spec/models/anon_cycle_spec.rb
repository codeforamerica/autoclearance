require 'rails_helper'

describe AnonCycle do
  describe '#build_from_parser' do
    it 'creates AnonCycles and AnonEvents from parser output' do
      event_1 = build_court_event(
        date: Date.new(1999, 1, 5),
        courthouse: 'Some courthouse'
      )

      event_2 = build_court_event(
        date: Date.new(1991, 3, 14),
        courthouse: 'CASC San Francisco'
      )

      cycle = RapSheetParser::Cycle.new(events: [event_1, event_2])

      rap_sheet = build_rap_sheet(events: [event_1, event_2])

      anon_cycle = described_class.build_from_parser(cycle: cycle, rap_sheet: rap_sheet)
      events = anon_cycle.anon_events
      expect(events.length).to eq 2
      expect(events.map(&:agency)).to contain_exactly('CASC San Francisco', 'Some courthouse')
    end
  end
end
