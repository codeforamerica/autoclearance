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

    it 'returns false if rap sheet level disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_conviction_event(counts: [eligible_count])

      eligibility = double(disqualifiers?: true)

      expect(described_class.new(eligible_count).csv_eligibility_column(EventWithEligibility.new(event), eligibility)).to eq false
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

  describe '#eligible?' do
    it 'returns true if prop64 conviction and no disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_conviction_event(
        date: Date.today - 7.days,
        case_number: '1',
        counts: [eligible_count]
      )

      rap_sheet = build_rap_sheet(events: ([event]))
      eligibility = new_rap_sheet(rap_sheet)

      expect(described_class.new(eligible_count).eligible?(EventWithEligibility.new(event), eligibility)).to eq true
    end

    it 'returns false if rap sheet level disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_conviction_event(counts: [eligible_count])

      eligibility = double(disqualifiers?: true)

      expect(described_class.new(eligible_count).eligible?(EventWithEligibility.new(event), eligibility)).to eq false
    end

    it 'returns true if possible plea bargain' do
      eligibility = new_rap_sheet(build_rap_sheet)
      event = EventWithEligibility.new(build_conviction_event)
      count = described_class.new(build_court_count(code: 'PC', section: '32'))
      
      plea_bargain_classifier = instance_double(PleaBargainClassifier, possible_plea_bargain?: true)
      allow(PleaBargainClassifier).to receive(:new).with(event: event, count: count).
        and_return(plea_bargain_classifier)

      expect(count.eligible?(event, eligibility)).to eq(true)
    end
  end

  def new_rap_sheet(rap_sheet, logger: Logger.new(StringIO.new))
    RapSheetWithEligibility.new(rap_sheet, logger: logger)
  end
end
