require 'rails_helper'

describe AnonRapSheet do
  describe '#create_from_parser' do
    it 'creates from parser output' do
      text = <<~TEXT
        blah
        DOB/19950504   SEX/M  RAC/WOOKIE
        NAM/01 BACCA, CHEW
            02 BACCA, CHEW E.
            03 WOOKIE, CHEWBACCA
        * * * *
        ARR/DET/CITE:         NAM:02  DOB:19750405
        19930407  CAPD SAN FRANCISCO
        CNT:01     #2223334
          11360(A) HS-GIVE/ETC MARIJ OVER 1 OZ/28.5 GRM
          DISPO:PROS REJ-COMB W/OTHER CNTS
        CNT:02
          11359 HS-POSSESS MARIJUANA FOR SALE
        - - - -
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
      expect(anon_rap_sheet.county).to eq 'Some county'
      expect(anon_rap_sheet.year_of_birth).to eq 1995
      expect(anon_rap_sheet.sex).to eq 'M'
      expect(anon_rap_sheet.race).to eq 'WOOKIE'

      cycle = anon_rap_sheet.anon_cycles.first
      expect(cycle.anon_events.count).to eq 3

      court_event_1 = cycle.anon_events[0]
      expect(court_event_1.event_type).to eq 'court'
      expect(court_event_1.agency).to eq 'CASC San Francisco'
      expect(court_event_1.date).to eq Date.new(1982, 7, 8)

      count_1 = court_event_1.anon_counts[0]
      expect(count_1.code).to eq 'PC'
      expect(count_1.section).to eq '4056'
      expect(count_1.anon_disposition.disposition_type).to eq('convicted')

      court_event_2 = cycle.anon_events[1]
      expect(court_event_2.event_type).to eq 'court'
      count_2 = court_event_2.anon_counts[0]
      expect(count_2.anon_disposition.disposition_type).to eq('convicted')

      arrest_event = cycle.anon_events[2]
      expect(arrest_event.event_type).to eq 'arrest'
      expect(arrest_event.agency).to eq 'CAPD SAN FRANCISCO'
      arrest_count = arrest_event.anon_counts[0]
      expect(arrest_count.code).to eq 'HS'
      expect(arrest_count.section).to eq '11360(a)'
      expect(arrest_count.anon_disposition.disposition_type).to eq('prosecutor_rejected')
    end

    it 'handles unknown personal info' do
      text = <<~TEXT
        blah blah
        * * * *
        ARR/DET/CITE:         NAM:02  DOB:19750405
        19930407  CAPD SAN FRANCISCO
        CNT:01     #2223334
          11360(A) HS-GIVE/ETC MARIJ OVER 1 OZ/28.5 GRM
          DISPO:PROS REJ-COMB W/OTHER CNTS
        CNT:02
          11359 HS-POSSESS MARIJUANA FOR SALE
        * * * END OF MESSAGE * * *
      TEXT

      rap_sheet = RapSheetParser::Parser.new.parse(text)

      described_class.create_or_update(
        text: text,
        county: 'Some county',
        rap_sheet: rap_sheet
      )

      anon_rap_sheet = AnonRapSheet.first
      expect(anon_rap_sheet.county).to eq 'Some county'
      expect(anon_rap_sheet.year_of_birth).to eq nil
      expect(anon_rap_sheet.sex).to eq nil
      expect(anon_rap_sheet.race).to eq nil

      cycle = anon_rap_sheet.anon_cycles.first
      expect(cycle.anon_events.count).to eq 1
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
