require 'rails_helper'

describe CountWithEligibility do
  let(:count) { build_court_count(code: code, section: section) }

  subject { described_class.new(count) }

  describe '#potentially_eligible?' do
    let(:event) { EventWithEligibility.new(build_conviction_event) }
    context 'when the count is an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359' }
      it 'returns true' do
        expect(subject.potentially_eligible?(event)).to eq true
      end
    end

    context 'when the count is a subsection of an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359(a)' }
      it 'returns true' do
        expect(subject.potentially_eligible?(event)).to eq true
      end
    end

    context 'when the count is an ineligible code' do
      let(:code) { 'HS' }
      let(:section) { '12345' }
      it 'returns false' do
        expect(subject.potentially_eligible?(event)).to eq false
      end
    end

    context 'when the count is an ineligible subsection' do
      let(:code) { 'HS' }
      let(:section) { '11359(d)' }
      it 'returns false' do
        expect(subject.potentially_eligible?(event)).to eq false
      end
    end

    context 'plea bargains' do
      it 'returns true for accessory charge with prop64 charge in the cycle' do
        text = <<-TEXT
          CII/A99000099
          DOB/19660119 SEX/M RAC/WHITE
          HGT/502 WGT/317 EYE/GRN HAIR/PNK POB/CA
          NAM/01 LASTY, FIRSTY
  
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO
  
          CNT:01     #111 
            11357 HS-BLAH
  
          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101 DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO
  
          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED   
            CONV STATUS:MISDEMEANOR   
            SEN: 12 DAYS JAIL
        TEXT

        rap_sheet = RapSheetParser::Parser.new.parse(text)

        eligibility = new_rap_sheet(rap_sheet)
        event = EventWithEligibility.new(eligibility.eligible_events[0])
        count = CountWithEligibility.new(event.counts[0])
        expect(count.code_section).to eq('PC 32')
        expect(count.potentially_eligible?(event)).to eq(true)
      end

      it 'returns false for accessory charge with no prop64 charge in the cycle' do
        text = <<-TEXT
          CII/A99000099
          DOB/19660119 SEX/M RAC/WHITE
          HGT/502 WGT/317 EYE/GRN HAIR/PNK POB/CA
          NAM/01 LASTY, FIRSTY
  
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO
  
          CNT:01     #111 
            496 PC-RECEIVE/ETC KNOWN STOLEN PROPERTY
  
          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101 DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO
  
          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED   
            CONV STATUS:MISDEMEANOR   
            SEN: 12 DAYS JAIL
        TEXT

        rap_sheet = RapSheetParser::Parser.new.parse(text)

        eligibility = new_rap_sheet(rap_sheet)
        event = EventWithEligibility.new(eligibility.eligible_events[0])
        count = CountWithEligibility.new(event.counts[0])
        expect(count.code_section).to eq('PC 32')
        expect(count.potentially_eligible?(event)).to eq(false)
      end
    end
  end

  describe '#csv_eligibility_column' do
    it 'returns true if prop64 conviction and no disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_conviction_event(
        date: Date.today - 7.days,
        case_number: '1',
        counts: [eligible_count]
      )

      rap_sheet = build_rap_sheet(events: ([event]))
      eligibility = new_rap_sheet(rap_sheet)

      expect(described_class.new(eligible_count).csv_eligibility_column(EventWithEligibility.new(event), eligibility)).to eq true
    end

    it 'returns false if registered sex offender' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_conviction_event(
        date: Date.today - 7.days,
        case_number: '1',
        counts: [eligible_count]
      )

      registration = RapSheetParser::RegistrationEvent.new(date: Date.today, code_section: 'PC 290')

      rap_sheet = build_rap_sheet(events: ([registration, event]))
      eligibility = new_rap_sheet(rap_sheet)

      expect(described_class.new(eligible_count).csv_eligibility_column(EventWithEligibility.new(event), eligibility)).to eq false
    end

    it 'returns false if contains any superstrikes' do
      eligible_count = build_court_count(code: 'HS', section: '11357')
      superstrike = build_court_count(code: 'PC', section: '187')

      event = build_conviction_event(
        date: Date.today - 7.days,
        case_number: '1',
        counts: [eligible_count, superstrike]
      )

      rap_sheet = build_rap_sheet(events: ([event]))
      eligibility = new_rap_sheet(rap_sheet)

      expect(described_class.new(eligible_count).csv_eligibility_column(EventWithEligibility.new(event), eligibility)).to eq false
    end

    it 'returns false if there are three distinct conviction events which include the same eligible code_section' do
      event1_count = build_court_count(code: 'HS', section: '11357')
      event_1 = build_conviction_event(case_number: '111', counts: [event1_count])

      event2_count = build_court_count(code: 'HS', section: '11357')
      event_2 = build_conviction_event(case_number: '222', counts: [event2_count])

      event3_count = build_court_count(code: 'HS', section: '11357')
      event_3 = build_conviction_event(case_number: '333', counts: [event3_count])

      subject = described_class.new(event2_count)

      rap_sheet = build_rap_sheet(events: ([event_1, event_2]))
      expect(subject.csv_eligibility_column(
        EventWithEligibility.new(event_2),
        new_rap_sheet(rap_sheet)
      )).to eq true

      rap_sheet = build_rap_sheet(events: ([event_1, event_2, event_3]))
      expect(subject.csv_eligibility_column(
        EventWithEligibility.new(event_2),
        new_rap_sheet(rap_sheet)
      )).to eq false
    end

    context 'plea bargain detection' do
      it 'can consider PC32 / HS11364 as dismissable if we think it was a plea bargain from prop64 dismissable code' do
        text = <<-TEXT
          CII/A99000099
          DOB/19660119 SEX/M RAC/WHITE
          HGT/502 WGT/317 EYE/GRN HAIR/PNK POB/CA
          NAM/01 LASTY, FIRSTY
  
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO
  
          CNT:01     #111 
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH
  
          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101 DISPO:PROS REJ-OTHER
  
          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
          19980101 DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO
  
          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED   
            CONV STATUS:MISDEMEANOR   
            SEN: 12 DAYS JAIL
        TEXT

        rap_sheet = RapSheetParser::Parser.new.parse(text)

        eligibility = new_rap_sheet(rap_sheet)
        event = EventWithEligibility.new(eligibility.eligible_events[0])
        count = described_class.new(event.counts[0])
        expect(count.code_section).to eq('PC 32')
        expect(count.csv_eligibility_column(event, eligibility)).to eq(true)
      end

      it 'returns false for plea bargain with disqualifier' do
        text = <<-TEXT
          CII/A99000099
          DOB/19660119 SEX/M RAC/WHITE
          HGT/502 WGT/317 EYE/GRN HAIR/PNK POB/CA
          NAM/01 LASTY, FIRSTY
  
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO
  
          CNT:01     #111 
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH
  
          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101 DISPO:PROS REJ-OTHER
  
          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
          19980101 DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO
  
          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED   
            CONV STATUS:MISDEMEANOR   
            SEN: 12 DAYS JAIL

          CNT:02
            187 PC-SUPERSTRIKE
          *DISPO:CONVICTED   
            CONV STATUS:MISDEMEANOR   
            SEN: 12 DAYS JAIL
        TEXT

        rap_sheet = RapSheetParser::Parser.new.parse(text)

        eligibility = new_rap_sheet(rap_sheet)
        event = EventWithEligibility.new(eligibility.eligible_events[0])
        count = described_class.new(event.counts[0])
        expect(count.code_section).to eq('PC 32')
        expect(count.csv_eligibility_column(event, eligibility)).to eq(false)
      end

      it 'can consider PC32 / HS11364 as "maybe" dismissible if there were other non-prop64 charges in the arrest or court event' do
        text = <<-TEXT
          CII/A99000099
          DOB/19660119 SEX/M RAC/WHITE
          HGT/502 WGT/317 EYE/GRN HAIR/PNK POB/CA
          NAM/01 LASTY, FIRSTY
  
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO
  
          CNT:01     #111 
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH
  
          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101 DISPO:PROS REJ-OTHER
  
          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
          19980101 DISPO:PROS REJ-OTHER
  
          CNT:04
            496 PC-RECEIVE/ETC KNOWN STOLEN PROPERTY
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO
  
          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED   
            CONV STATUS:MISDEMEANOR   
            SEN: 12 DAYS JAIL
        TEXT

        rap_sheet = RapSheetParser::Parser.new.parse(text)

        eligibility = new_rap_sheet(rap_sheet)
        event = EventWithEligibility.new(eligibility.eligible_events[0])
        count = CountWithEligibility.new(event.counts[0])
        expect(count.code_section).to eq('PC 32')
        expect(count.csv_eligibility_column(event, eligibility)).to eq('maybe')
      end
    end
  end

  def new_rap_sheet(rap_sheet, logger: Logger.new(StringIO.new))
    RapSheetWithEligibility.new(rap_sheet, logger: logger)
  end
end
