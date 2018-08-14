require 'rails_helper'

describe AnonRapSheet do
  describe '#create_from_parser' do
    it 'creates from parser output' do
      text = <<~TEXT
        blah blah
        SEX/M
        NAM/01 BACCA, CHEW
            02 BACCA, CHEW E.
            03 WOOKIE, CHEWBACCA
        * * * *
        COURT:
        19820708 CASC SAN FRANCISCO

        CNT: 001 #456
        4056 PC-BREAKING AND ENTERING
        *DISPO:CONVICTED
        MORE INFO ABOUT THIS COUNT
        - - - -
        COURT:
        19820915 CAMC SAN FRANCISCO

        CNT: 001 #456
        bla bla
        DISPO:CONVICTED
        * * * END OF MESSAGE * * *
      TEXT

      rap_sheet = RapSheetParser::Parser.new.parse(text)

      described_class.create_or_update(
        text: text,
        county: 'Some county',
        rap_sheet: rap_sheet
      )
      
      anon_rap_sheet = AnonRapSheet.first
      cycle = anon_rap_sheet.anon_cycles.first
      court_event_1 = cycle.anon_events[0]
      court_event_2 = cycle.anon_events[1]
      count_1 = court_event_1.anon_counts[0]
      
      expect(anon_rap_sheet.county).to eq 'Some county'
      expect(court_event_1.agency).to eq 'CASC San Francisco'
      expect(court_event_1.date).to eq Date.new(1982, 7, 8)
      expect(court_event_2.agency).to eq 'CAMC San Francisco'
      expect(count_1.code).to eq 'PC'
      expect(count_1.section).to eq '4056'
    end

    it 'when the same rap sheet is uploaded twice, it overwrites the database contents' do
      described_class.create_or_update(
        text: 'rap sheet 1',
        county: 'Some county',
        rap_sheet: build_rap_sheet(events: [build_court_event, build_court_event])
      )

      expect(AnonRapSheet.count).to eq 1
      expect(AnonRapSheet.first.county).to eq 'Some county'
      expect(AnonEvent.count).to eq 2

      described_class.create_or_update(
        text: 'rap sheet 1',
        county: 'Different County',
        rap_sheet: build_rap_sheet(events: [build_court_event])
      )

      expect(AnonRapSheet.count).to eq 1
      expect(AnonRapSheet.first.county).to eq 'Different County'
      expect(AnonEvent.count).to eq 1

      described_class.create_or_update(
        text: 'rap sheet 2',
        county: 'Some county',
        rap_sheet: build_rap_sheet(events: [build_court_event, build_court_event, build_court_event])
      )

      expect(AnonRapSheet.count).to eq 2
      expect(AnonEvent.count).to eq 4
    end
  end
end
