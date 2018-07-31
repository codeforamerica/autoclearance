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
      context 'when the count is a possible plea bargain' do
        let(:code) { 'PC' }
        let(:section) { '32' }

        before do
          plea_bargain_classifier = instance_double(PleaBargainClassifier, possible_plea_bargain?: true)
          allow(PleaBargainClassifier).to receive(:new).with(event: event, count: subject).
            and_return(plea_bargain_classifier)
        end

        it 'returns true' do
          expect(subject.potentially_eligible?(event)).to eq true
        end
      end

      context 'when the count is not a possible plea bargain' do
        let(:code) { 'PC' }
        let(:section) { '32' }

        before do
          plea_bargain_classifier = instance_double(PleaBargainClassifier, possible_plea_bargain?: false)
          allow(PleaBargainClassifier).to receive(:new).with(event: event, count: subject).
            and_return(plea_bargain_classifier)
        end

        it 'returns false' do
          expect(subject.potentially_eligible?(event)).to eq false
        end
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
      let(:code) {}
      let(:section) {}
      
      it 'returns true if plea bargain' do
        eligibility = new_rap_sheet(build_rap_sheet)
        event = EventWithEligibility.new(build_conviction_event)
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new).with(event: event, count: subject).
          and_return(plea_bargain_classifier)
        
        expect(subject.csv_eligibility_column(event, eligibility)).to eq(true)
      end

      it 'returns false for plea bargain with disqualifier' do
        superstrike = build_court_count(code: 'PC', section: '187')
        conviction_event = build_conviction_event(counts: [superstrike])
        eligibility = new_rap_sheet(build_rap_sheet(events: [conviction_event]))
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: true)
        event = EventWithEligibility.new(conviction_event)
        allow(PleaBargainClassifier).to receive(:new).with(event: event, count: subject).
          and_return(plea_bargain_classifier)
        
        expect(subject.csv_eligibility_column(event, eligibility)).to eq(false)
      end

      it 'returns "maybe" if possible plea bargain only' do
        eligibility = new_rap_sheet(build_rap_sheet)
        event = EventWithEligibility.new(build_conviction_event)
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: false, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new).with(event: event, count: subject).
          and_return(plea_bargain_classifier)
        
        expect(subject.csv_eligibility_column(event, eligibility)).to eq('maybe')
      end
    end
  end

  def new_rap_sheet(rap_sheet, logger: Logger.new(StringIO.new))
    RapSheetWithEligibility.new(rap_sheet, logger: logger)
  end
end
