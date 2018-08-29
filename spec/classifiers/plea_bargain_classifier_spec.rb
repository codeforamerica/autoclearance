require 'rails_helper'

describe PleaBargainClassifier do
  let(:event) do
    rap_sheet = RapSheetParser::Parser.new.parse(text)
    eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)
    EventWithEligibility.new(eligibility.eligible_events[0])
  end
  let(:count) { CountWithEligibility.new(event.counts[0]) }
  let(:subject) { described_class.new(event: event, count: count) }

  describe '#plea_bargain?' do
    context 'plea bargain from prop64 dismissable code' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_plea_bargain
      end
    end

    context 'rejected non-prop64 counts in the cycle' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH

          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
           DISPO:PROS REJ-OTHER

          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
           DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_plea_bargain
      end
    end

    context 'rejected non-prop64 counts due to updates in the cycle' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH

          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101
            DISPO:PROS REJ-OTHER

          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
          19980101
            DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_plea_bargain
      end
    end

    context 'accessory charge with dismissed prop64 charge in the court event' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
          CNT:02
            11357 HS-BLAH
          *DISPO:DISMISSED
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_plea_bargain
      end
    end

    context 'accessory charge with dismissed prop64 charge in the court event' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO
          CNT:01
            11357 HS-BLAH
          *DISPO:DISMISSED
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_plea_bargain
      end
    end

    context 'there were other non-prop64 charges in the arrest or court event' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH

          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101
            DISPO:PROS REJ-OTHER

          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
          19980101
            DISPO:PROS REJ-OTHER

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
      end

      it 'returns true' do
        expect(subject).not_to be_plea_bargain
      end
    end
  end

  describe '#possible_plea_bargain?' do
    context 'accessory charge with prop64 charge in the cycle' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            11357 HS-BLAH

          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101
            DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_possible_plea_bargain
      end
    end

    context 'accessory charge with dismissed prop64 charge in the court event' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
          CNT:02
            11357 HS-BLAH
          *DISPO:DISMISSED
        TEXT
      end

      it 'returns true' do
        expect(subject).to be_possible_plea_bargain
      end
    end

    context 'there were other non-prop64 charges in the arrest or court event' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY
          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            11360 HS-SELL/TRANSPORT/ETC MARIJUANA/HASH

          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101
            DISPO:PROS REJ-OTHER

          CNT:03  11364 HS-POSSESS CONTROL SUBSTANCE PARAPHERNA
          19980101
            DISPO:PROS REJ-OTHER

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
      end

      it 'returns true' do
        expect(subject).to be_possible_plea_bargain
      end
    end

    context 'accessory charge with no prop64 charge in the cycle' do
      let(:text) do
        <<-TEXT
          NAM/01 LASTY, FIRSTY

          * * * *
          ARR/DET/CITE:         NAM:01  DOB:19750101
          19980101  CAPD SAN FRANCISCO

          CNT:01     #111
            496 PC-RECEIVE/ETC KNOWN STOLEN PROPERTY

          CNT:02  135 PC-DESTROY/CONCEAL EVIDENCE
          19980101
            DISPO:PROS REJ-OTHER
          - - - -
          COURT:                NAM:01
          19980101  CAMC SAN FRANCISCO

          CNT:01     #222
            32 PC-ACCESSORY
          *DISPO:CONVICTED
            CONV STATUS:MISDEMEANOR
            SEN: 12 DAYS JAIL
        TEXT
      end

      it 'returns false' do
        expect(subject).not_to be_possible_plea_bargain
      end
    end
  end
end
