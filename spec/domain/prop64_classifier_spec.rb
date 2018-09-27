require 'rails_helper'

describe Prop64Classifier do
  let(:count) { build_count(code: code, section: section) }
  let(:event) { build_court_event(counts: [count]) }
  let(:event_with_eligibility) { EventWithEligibility.new(event: event, eligibility: eligibility) }
  let(:code) {}
  let(:section) {}
  let(:eligibility) { build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet(events: [event])) }

  subject { described_class.new(count: count, event: event_with_eligibility, eligibility: eligibility) }

  describe '#potentially_eligible?' do
    context 'when the count is an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359' }
      it 'returns true' do
        expect(subject).to be_potentially_eligible
      end
    end

    context 'when the count is a subsection of an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359(a)' }
      it 'returns true' do
        expect(subject).to be_potentially_eligible
      end
    end

    context 'when the count is an ineligible code' do
      let(:code) { 'HS' }
      let(:section) { '12345' }
      it 'returns false' do
        expect(subject).not_to be_potentially_eligible
      end
    end

    context 'when the count is an ineligible subsection' do
      let(:code) { 'HS' }
      let(:section) { '11359(d)' }
      it 'returns false' do
        expect(subject).not_to be_potentially_eligible
      end
    end

    context 'when excluding misdemeanors' do
      let(:county) { build_county(misdemeanors: false) }
      let(:eligibility) { build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet(events: [event]), county: county) }
      let(:count) { build_count(code: 'HS', section: '11359', disposition: build_disposition(severity: 'M')) }

      it 'returns false' do
        expect(subject).not_to be_potentially_eligible
      end
    end

    context 'plea bargains' do
      context 'when the count is a possible plea bargain' do
        before do
          plea_bargain_classifier = instance_double(PleaBargainClassifier, possible_plea_bargain?: true)
          allow(PleaBargainClassifier).to receive(:new)
            .with(subject)
            .and_return(plea_bargain_classifier)
        end

        it 'returns true' do
          expect(subject.potentially_eligible?).to eq true
        end
      end

      context 'when the count is not a possible plea bargain' do
        before do
          plea_bargain_classifier = instance_double(PleaBargainClassifier, possible_plea_bargain?: false)
          allow(PleaBargainClassifier).to receive(:new)
            .with(subject)
            .and_return(plea_bargain_classifier)
        end

        it 'returns false' do
          expect(subject.potentially_eligible?).to eq false
        end
      end
    end
  end

  describe '#eligible?' do
    let(:has_three_convictions_of_same_type?) { false }
    let(:disqualifiers?) { false }
    let(:code) { 'HS' }
    let(:section) { '11358' }
    let(:eligibility) { double(disqualifiers?: disqualifiers?, has_three_convictions_of_same_type?: has_three_convictions_of_same_type?, county: build_county) }

    it 'returns true if prop64 conviction and no disqualifiers' do
      expect(subject.eligible?).to eq 'yes'
    end

    context 'rap sheet disqualifiers' do
      let(:disqualifiers?) { true }
      it 'returns false if rap sheet level disqualifiers' do
        expect(subject.eligible?).to eq 'no'
      end
    end

    context '2 prop 64 priors' do
      let(:has_three_convictions_of_same_type?) { true }
      it 'returns false if rap sheet level disqualifiers' do
        expect(subject.eligible?).to eq 'no'
      end
    end

    context 'plea bargain detection' do
      it 'returns true if plea bargain' do
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: true, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new)
          .with(subject)
          .and_return(plea_bargain_classifier)

        expect(subject.eligible?).to eq('yes')
      end

      it 'returns "maybe" if possible plea bargain only' do
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: false, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new)
          .with(subject)
          .and_return(plea_bargain_classifier)

        expect(subject.eligible?).to eq('maybe')
      end
    end
  end

  describe '#has_two_prop_64_priors?' do
    let(:code) { 'HS' }
    let(:section) { '11358' }
    let(:eligibility) { double(has_three_convictions_of_same_type?: has_three_convictions_of_same_type?) }
    let(:result) { subject.has_two_prop_64_priors? }

    context 'if there are fewer than 3 of a prop-64 two-priors relevant code' do
      let(:has_three_convictions_of_same_type?) { false }

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'if there 3 or more of a prop-64 two-priors relevant code' do
      let(:has_three_convictions_of_same_type?) { true }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'if there 3 or more of a non-relevant code' do
      let(:section) { '11357' }
      let(:has_three_convictions_of_same_type?) {}

      it 'returns false' do
        expect(result).to be false
      end
    end
  end
end
