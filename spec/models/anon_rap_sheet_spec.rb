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
        CONV STATUS:FELONY
        SEN: 3 YEARS PRISON
        - - - -
        COURT:
        19820915 CAMC SAN FRANCISCO

        CNT: 001 #456
        11358 HS-CULTIVATION OF MARIJUANA
        DISPO:CONVICTED
        CONV STATUS:MISDEMEANOR
        SEN: 3 MONTHS PROBATION,6 MONTHS JAIL
        * * * END OF MESSAGE * * *
      TEXT

      described_class.create_or_update(
        text: text,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text)
      )

      anon_rap_sheet = AnonRapSheet.first
      expect(anon_rap_sheet.county).to eq 'Some county'
      expect(anon_rap_sheet.year_of_birth).to eq 1995
      expect(anon_rap_sheet.sex).to eq 'M'
      expect(anon_rap_sheet.race).to eq 'WOOKIE'

      rap_sheet_properties = anon_rap_sheet.rap_sheet_properties
      expect(rap_sheet_properties.deceased).to eq false
      expect(rap_sheet_properties.has_sex_offender_registration).to eq false
      expect(rap_sheet_properties.has_superstrikes).to eq false

      cycle = anon_rap_sheet.anon_cycles.first
      expect(cycle.anon_events.count).to eq 3

      court_event_1 = cycle.anon_events[0]
      expect(court_event_1.event_type).to eq 'court'
      expect(court_event_1.agency).to eq 'CASC San Francisco'
      expect(court_event_1.date).to eq Date.new(1982, 7, 8)

      event_properties_1 = court_event_1.event_properties
      expect(event_properties_1.has_felonies).to eq true
      expect(event_properties_1.has_probation).to eq false
      expect(event_properties_1.has_probation_violations).to eq false
      expect(event_properties_1.has_prison).to eq true
      expect(event_properties_1.dismissed_by_pc1203).to eq false

      count_1 = court_event_1.anon_counts[0]
      expect(count_1.code).to eq 'PC'
      expect(count_1.section).to eq '4056'
      expect(count_1.anon_disposition.disposition_type).to eq('convicted')
      expect(count_1.anon_disposition.text).to eq('*DISPO:CONVICTED')

      count_properties_1 = count_1.count_properties
      expect(count_properties_1.has_prop_64_code).to eq false
      expect(count_properties_1.has_two_prop_64_priors).to eq false
      expect(count_properties_1.prop_64_plea_bargain).to eq 'no'

      eligibility_estimate_1 = count_properties_1.eligibility_estimate
      expect(eligibility_estimate_1.prop_64_eligible).to eq 'no'
      expect(eligibility_estimate_1.count_properties).to eq count_properties_1

      court_event_2 = cycle.anon_events[1]
      expect(court_event_2.event_type).to eq 'court'

      count_2 = court_event_2.anon_counts[0]
      expect(count_2.anon_disposition.disposition_type).to eq('convicted')

      count_properties_2 = count_2.count_properties
      expect(count_properties_2.has_prop_64_code).to eq true
      expect(count_properties_2.has_two_prop_64_priors).to eq false
      expect(count_properties_2.prop_64_plea_bargain).to eq 'no'

      event_properties_2 = court_event_2.event_properties
      expect(event_properties_2.has_felonies).to eq false
      expect(event_properties_2.has_probation).to eq true
      expect(event_properties_2.has_probation_violations).to eq false
      expect(event_properties_2.has_prison).to eq false
      expect(event_properties_1.dismissed_by_pc1203).to eq false

      eligibility_estimate_2 = count_properties_2.eligibility_estimate
      expect(eligibility_estimate_2.prop_64_eligible).to eq 'yes'
      expect(eligibility_estimate_2.count_properties).to eq count_properties_2

      arrest_event = cycle.anon_events[2]
      expect(arrest_event.event_type).to eq 'arrest'
      expect(arrest_event.agency).to eq 'CAPD SAN FRANCISCO'
      arrest_count = arrest_event.anon_counts[0]
      expect(arrest_count.code).to eq 'HS'
      expect(arrest_count.section).to eq '11360(a)'
      expect(arrest_count.anon_disposition.disposition_type).to eq('prosecutor_rejected')
      expect(arrest_count.anon_disposition.text).to eq('DISPO:PROS REJ-COMB W/OTHER CNTS')
    end

    it 'saves all known event types in database' do
      text = <<~TEXT
        blah
        * * * *
        REGISTRATION:          NAM:07
        19840217  CAID ALAMEDA CO

        CNT:01     #EIC768
          11590 HS-REGISTRATION OF CNTL SUB OFFENDER
        ----
        20060523  CASD CORR WASCO


        CNT:01     #Q123445
          290(E)(1) PC-PREREGISTRATION OF SEX OFFENDER
        ***********************************************************************
        **                                                                      **
        **  FOR CURRENT REGISTRANT ADDRESS INFORMATION INQUIRE INTO             **
        **  THE CALIFORNIA SEX AND ARSON REGISTRY (CSAR)                        **
        **                                                                      **
        ***********************************************************************

        * * * *
        ARR/DET/CITE:         NAM:02  DOB:19750405
        19930407  CAPD SAN FRANCISCO
        CNT:01     #2223334
          11360(A) HS-GIVE/ETC MARIJ OVER 1 OZ/28.5 GRM
          DISPO:PROS REJ-COMB W/OTHER CNTS
        CNT:02
          11359 HS-POSSESS MARIJUANA FOR SALE
        - - - -
        SUPPLEMENTAL ARR:      NAM:01
          20110124  CASO SAN FRANCISCO

          CNT:01     #024435345
            32 PC-ACCESSORY
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
        * * * *
        PROBATION:             NAM:01
        19841228  CAPR SAN FRANCISCO

        CNT:01     #976597
          11359 HS-POSSESS MARIJUANA FOR SALE
           SEN: 3 YEARS PROBATION
           COM: CRT CASE NBR 547789
        * * * *

        CUSTODY:CDC            NAM:01
        19851219  CASD CORRECTIONS

        CNT:01     #5464523
          459 PC-BURGLARY:FIRST DEGREE
           CRT #12345


        CNT:02
           -ATTEMPTED
          459 PC-BURGLARY:FIRST DEGREE
           SEN FROM: SAN MATEO CO   CRT #54323
           SEN: 32 MONTHS PRISON

        19870201

         DISPO:PAROLED FROM CDC
           RECVD BY:CAPA SAN MATEO CO
        * * * *
        MENTAL HLTH CUS/SUPV   NAM:01

        19910625  CAHO ATASCADERO STATE

        CNT:01     #897804-2
          1370 PC-MENTALLY INCOMPETENT
        * * * *

        DECEASED:              NAM:01
        20130817  CACO SAN FRANCISCO

        CNT:01     #0064-64074-20790144
          DECEASED

            COM: SCN-L87G2300013
        * * * END OF MESSAGE * * *
      TEXT

      described_class.create_or_update(
        text: text,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text)
      )

      expect(AnonEvent.where(event_type: 'arrest').count).to eq 1
      arrest_event = AnonEvent.find_by(event_type: 'arrest')
      expect(arrest_event.agency).to eq 'CAPD SAN FRANCISCO'
      expect(arrest_event.date).to eq Date.new(1993, 4, 7)
      expect(arrest_event.anon_counts.count).to eq(2)
      expect(arrest_event.anon_counts[0].code).to eq('HS')
      expect(arrest_event.anon_counts[0].section).to eq('11360(a)')
      expect(arrest_event.anon_counts[0].description).to eq('GIVE/ETC MARIJ OVER 1 OZ/28.5 GRM')
      expect(arrest_event.anon_counts[0].anon_disposition.severity).to be_nil
      expect(arrest_event.anon_counts[0].anon_disposition.disposition_type).to eq('prosecutor_rejected')
      expect(arrest_event.anon_counts[1].code).to eq('HS')
      expect(arrest_event.anon_counts[1].section).to eq('11359')
      expect(arrest_event.anon_counts[1].description).to eq('POSSESS MARIJUANA FOR SALE')
      expect(arrest_event.anon_counts[1].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'deceased').count).to eq 1
      deceased_event = AnonEvent.find_by(event_type: 'deceased')
      expect(deceased_event.agency).to eq 'CACO SAN FRANCISCO'
      expect(deceased_event.date).to eq Date.new(2013, 8, 17)
      expect(deceased_event.anon_counts.count).to eq(1)
      expect(deceased_event.anon_counts[0].code).to be_nil
      expect(deceased_event.anon_counts[0].section).to be_nil
      expect(deceased_event.anon_counts[0].description).to be_nil
      expect(deceased_event.anon_counts[0].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'supplemental_arrest').count).to eq 1
      arrest_event = AnonEvent.find_by(event_type: 'supplemental_arrest')
      expect(arrest_event.agency).to eq 'CASO SAN FRANCISCO'
      expect(arrest_event.date).to eq Date.new(2011, 1, 24)
      expect(arrest_event.anon_counts.count).to eq(1)
      expect(arrest_event.anon_counts[0].code).to eq('PC')
      expect(arrest_event.anon_counts[0].section).to eq('32')
      expect(arrest_event.anon_counts[0].description).to eq('ACCESSORY')
      expect(arrest_event.anon_counts[0].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'mental_health').count).to eq 1
      arrest_event = AnonEvent.find_by(event_type: 'mental_health')
      expect(arrest_event.agency).to eq 'CAHO ATASCADERO STATE'
      expect(arrest_event.date).to eq Date.new(1991, 6, 25)
      expect(arrest_event.anon_counts.count).to eq(1)
      expect(arrest_event.anon_counts[0].code).to eq('PC')
      expect(arrest_event.anon_counts[0].section).to eq('1370')
      expect(arrest_event.anon_counts[0].description).to eq('MENTALLY INCOMPETENT')
      expect(arrest_event.anon_counts[0].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'court').count).to eq 1
      court_event = AnonEvent.find_by(event_type: 'court')
      expect(court_event.agency).to eq 'CASC San Francisco'
      expect(court_event.date).to eq Date.new(1993, 7, 8)
      expect(court_event.anon_counts.count).to eq(1)
      expect(court_event.anon_counts[0].code).to eq('PC')
      expect(court_event.anon_counts[0].section).to eq('4056')
      expect(court_event.anon_counts[0].description).to eq('BREAKING AND ENTERING')
      expect(court_event.anon_counts[0].anon_disposition.severity).to be_nil
      expect(court_event.anon_counts[0].anon_disposition.disposition_type).to eq('dismissed')

      expect(AnonEvent.where(event_type: 'applicant').count).to eq 1
      applicant_event = AnonEvent.find_by(event_type: 'applicant')
      expect(applicant_event.agency).to eq 'CASD SOCIAL SERV CCL-CRCB, SACRAMENTO'
      expect(applicant_event.date).to eq Date.new(2002, 12, 13)
      expect(applicant_event.anon_counts.count).to eq(1)
      expect(applicant_event.anon_counts[0].code).to be_nil
      expect(applicant_event.anon_counts[0].section).to be_nil
      expect(applicant_event.anon_counts[0].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'probation').count).to eq 1
      probation_event = AnonEvent.find_by(event_type: 'probation')
      expect(probation_event.agency).to eq 'CAPR SAN FRANCISCO'
      expect(probation_event.date).to eq Date.new(1984, 12, 28)
      expect(probation_event.anon_counts.count).to eq(1)
      expect(probation_event.anon_counts[0].code).to eq('HS')
      expect(probation_event.anon_counts[0].section).to eq('11359')
      expect(probation_event.anon_counts[0].description).to eq("POSSESS MARIJUANA FOR SALE\n   SEN: 3 YEARS PROBATION")
      expect(probation_event.anon_counts[0].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'custody').count).to eq 1
      custody_event = AnonEvent.find_by(event_type: 'custody')
      expect(custody_event.agency).to eq 'CASD CORRECTIONS'
      expect(custody_event.date).to eq Date.new(1985, 12, 19)
      expect(custody_event.anon_counts.count).to eq(2)
      expect(custody_event.anon_counts[0].code).to eq('PC')
      expect(custody_event.anon_counts[0].section).to eq('459')
      expect(custody_event.anon_counts[0].description).to eq("BURGLARY:FIRST DEGREE\n   CRT #12345")
      expect(custody_event.anon_counts[0].anon_disposition).to be_nil
      expect(custody_event.anon_counts[1].code).to eq('PC')
      expect(custody_event.anon_counts[1].section).to eq('459')
      expect(custody_event.anon_counts[1].description).to eq("BURGLARY:FIRST DEGREE\n   SEN FROM: SAN MATEO CO   CRT #54323\n   SEN: 32 MONTHS PRISON")
      expect(custody_event.anon_counts[1].anon_disposition).to be_nil

      expect(AnonEvent.where(event_type: 'registration').count).to eq 2
      narcotics_registration = AnonEvent.where(event_type: 'registration').first
      expect(narcotics_registration.agency).to eq 'CAID ALAMEDA CO'
      expect(narcotics_registration.date).to eq Date.new(1984, 2, 17)
      expect(narcotics_registration.anon_counts.count).to eq(1)
      expect(narcotics_registration.anon_counts[0].code).to eq('HS')
      expect(narcotics_registration.anon_counts[0].section).to eq('11590')
      expect(narcotics_registration.anon_counts[0].description).to eq('REGISTRATION OF CNTL SUB OFFENDER')
      expect(narcotics_registration.anon_counts[0].anon_disposition).to be_nil
      sex_offender_registration = AnonEvent.where(event_type: 'registration').second
      expect(sex_offender_registration.agency).to eq 'CASD CORR WASCO'
      expect(sex_offender_registration.date).to eq Date.new(2006, 5, 23)
      expect(sex_offender_registration.anon_counts.count).to eq(1)
      expect(sex_offender_registration.anon_counts[0].code).to eq('PC')
      expect(sex_offender_registration.anon_counts[0].section).to eq('290(e)(1)')
      expect(sex_offender_registration.anon_counts[0].description).to include('PREREGISTRATION OF SEX OFFENDER')
      expect(sex_offender_registration.anon_counts[0].anon_disposition).to be_nil
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

      described_class.create_or_update(
        text: text,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text)
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
      rap_sheet = build_rap_sheet(
        events: [build_court_event, build_court_event]
      )

      described_class.create_or_update(
        text: 'rap sheet 1',
        county: 'Some county',
        rap_sheet: rap_sheet
      )

      rap_sheet = build_rap_sheet(events: [build_court_event])

      expect(AnonRapSheet.count).to eq 1
      expect(AnonRapSheet.first.county).to eq 'Some county'
      expect(AnonEvent.count).to eq 2

      described_class.create_or_update(
        text: 'rap sheet 1',
        county: 'Different County',
        rap_sheet: rap_sheet
      )

      expect(AnonRapSheet.count).to eq 1
      expect(AnonRapSheet.first.county).to eq 'Different County'
      expect(AnonEvent.count).to eq 1

      rap_sheet = build_rap_sheet(events: [build_court_event, build_court_event, build_court_event])

      described_class.create_or_update(
        text: 'rap sheet 2',
        county: 'Some county',
        rap_sheet: rap_sheet
      )

      expect(AnonRapSheet.count).to eq 2
      expect(AnonEvent.count).to eq 4
    end

    it 'generates a unique checksum for the individual person' do
      text1 = <<~TEXT
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

      text2 = <<~TEXT
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

      text3 = <<~TEXT
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

      rap1 = described_class.create_or_update(
        text: text1,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text1)
      )

      rap2 = described_class.create_or_update(
        text: text2,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text2)
      )

      rap3 = described_class.create_or_update(
        text: text3,
        county: 'Some county',
        rap_sheet: RapSheetParser::Parser.new.parse(text3)
      )

      expect(rap1.person_unique_id).to eq(rap2.person_unique_id)
      expect(rap1.person_unique_id).not_to eq(rap3.person_unique_id)
    end
  end
end
