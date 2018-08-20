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

    it 'saves all known event types in database' do
      text = <<~TEXT
        blah
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
        19930708 CASC SAN FRANCISCO

        CNT: 001 #456
        4056 PC-BREAKING AND ENTERING
        DISPO:DISMISSED/FURTHERANCE OF JUSTICE
        MORE INFO ABOUT THIS COUNT
        * * * *
        APPLICANT:             NAM:01
        
        20021213  CASD SOCIAL SERV CCL-CRCB, SACRAMENTO
        
        CNT:01     #349540985
          APPLICANT RESIDNTL CARE FACILITY FOR ELDERLY
           COM: SCN-23475348 ATI-EIR090347KI

        20160807
         DISPO:NO LONGER INTERESTED
           COM: ACN-12039823947
        * * * END OF MESSAGE * * *
      TEXT

      rap_sheet = RapSheetParser::Parser.new.parse(text)

      described_class.create_or_update(
        text: text,
        county: 'Some county',
        rap_sheet: rap_sheet
      )

      expect(AnonEvent.where(event_type: 'arrest').count).to eq 1
      arrest_event = AnonEvent.find_by_event_type('arrest')
      expect(arrest_event.agency).to eq 'CAPD SAN FRANCISCO'
      expect(arrest_event.date).to eq Date.new(1993, 4, 7)
      expect(arrest_event.anon_counts.count).to eq(2)
      expect(arrest_event.anon_counts[0].code).to eq('HS')
      expect(arrest_event.anon_counts[0].section).to eq('11360(a)')
      expect(arrest_event.anon_counts[0].description).to eq('GIVE/ETC MARIJ OVER 1 OZ/28.5 GRM')
      expect(arrest_event.anon_counts[0].severity).to be_nil
      expect(arrest_event.anon_counts[0].anon_disposition.disposition_type).to eq('prosecutor_rejected')
      expect(arrest_event.anon_counts[1].code).to eq('HS')
      expect(arrest_event.anon_counts[1].section).to eq('11359')
      expect(arrest_event.anon_counts[1].description).to eq('POSSESS MARIJUANA FOR SALE')
      expect(arrest_event.anon_counts[1].severity).to be_nil
      expect(arrest_event.anon_counts[1].anon_disposition).to be_nil


      expect(AnonEvent.where(event_type: 'court').count).to eq 1
      court_event = AnonEvent.find_by_event_type('court')
      expect(court_event.agency).to eq 'CASC San Francisco'
      expect(court_event.date).to eq Date.new(1993, 7, 8)
      expect(court_event.anon_counts.count).to eq(1)
      expect(court_event.anon_counts[0].code).to eq('PC')
      expect(court_event.anon_counts[0].section).to eq('4056')
      expect(court_event.anon_counts[0].description).to eq('BREAKING AND ENTERING')
      expect(court_event.anon_counts[0].severity).to be_nil
      expect(court_event.anon_counts[0].anon_disposition.disposition_type).to eq('dismissed')

      expect(AnonEvent.where(event_type: 'applicant').count).to eq 1
      applicant_event = AnonEvent.find_by_event_type('applicant')
      expect(applicant_event.agency).to eq 'CASD SOCIAL SERV CCL-CRCB, SACRAMENTO'
      expect(applicant_event.date).to eq Date.new(2002, 12, 13)
      expect(applicant_event.anon_counts.count).to eq(1)
      expect(applicant_event.anon_counts[0].code).to be_nil
      expect(applicant_event.anon_counts[0].section).to be_nil
      # expect(applicant_event.anon_counts[0].description).to eq('APPLICANT RESIDNTL CARE FACILITY FOR ELDERLY')
      expect(applicant_event.anon_counts[0].severity).to be_nil
      # expect(applicant_event.anon_counts[1].anon_disposition.disposition_type).to eq('other_disposition_type')

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
      expect(anon_rap_sheet.person_unique_id).to eq nil

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

    it 'generates a unique checksum for the individual person' do
      text_1 = <<~TEXT
        blah
        CII/A12345678
        DOB/19950504   SEX/M  RAC/WOOKIE
        NAM/01 BACCA, CHEW
            02 BACCA, CHEW E.
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

      text_2 = <<~TEXT
        CII/A12345678
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
        * * * END OF MESSAGE * * *
      TEXT

      text_3 = <<~TEXT
        **LIVE SCAN
        CII/A99000099
        SEX/M RAC/WHITE
        HGT/502 WGT/317 EYE/GRN HAIR/PNK POB/CA
        NAM/01 SKYWALKER,LUKE JAY
            02 SKYWALKER,LUKE
        
        * * * *
        ARR/DET/CITE: NAM:02 DOB:19550505
        19840725  CASO LOS ANGELES
        
        CNT:01     #1111111
          11357 HS-POSSESS MARIJUANA
        
        CNT:02
          496 PC-RECEIVE/ETC KNOWN STOLEN PROPERTY
           COM: WARRANT NBR A-400000 BOTH CNTS
        
        CNT:03
          11358 HS-CULTIVATION MARIJUANA
        * * * END OF MESSAGE * * *
      TEXT

      rap_1 = described_class.create_or_update(
        text: text_1,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text_1)
      )

      rap_2 = described_class.create_or_update(
        text: text_2,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text_2)
      )

      rap_3 = described_class.create_or_update(
        text: text_3,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text_3)
      )

      expect(rap_1.person_unique_id).to eq(rap_2.person_unique_id)
      expect(rap_1.person_unique_id).not_to eq(rap_3.person_unique_id)
    end
  end
end
