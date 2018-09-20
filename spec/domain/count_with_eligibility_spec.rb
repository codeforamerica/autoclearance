require 'rails_helper'

describe CountWithEligibility do
  let(:count) { build_count(code: code, section: section) }
  let(:event) { EventWithEligibility.new(build_court_event(counts: [count])) }
  let(:code) {}
  let(:section) {}

  subject { described_class.new(count: count, event: event) }

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
    let(:count) { build_count(code: 'HS', section: '11358') }

    it 'returns true if prop64 conviction and no disqualifiers' do
      rap_sheet = build_rap_sheet(events: [event])
      eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

      expect(subject.eligible?(eligibility)).to eq 'yes'
    end

    it 'returns false if rap sheet level disqualifiers' do
      eligibility = double(disqualifiers?: true)

      expect(subject.eligible?(eligibility)).to eq 'no'
    end

    it 'returns false if it has 2 prop 64 priors' do
      eligibility = double(has_three_convictions_of_same_type?: true, disqualifiers?: false)
      expect(subject.eligible?(eligibility)).to eq 'no'
    end

    context 'plea bargain detection' do
      it 'returns true if plea bargain' do
        eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet)
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: true, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new)
          .with(subject)
          .and_return(plea_bargain_classifier)

        expect(subject.eligible?(eligibility)).to eq('yes')
      end

      it 'returns "maybe" if possible plea bargain only' do
        eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet)
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: false, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new)
          .with(subject)
          .and_return(plea_bargain_classifier)

        expect(subject.eligible?(eligibility)).to eq('maybe')
      end
    end
  end

  describe '#has_two_prop_64_priors?' do
    let(:code) { 'HS' }
    let(:section) { '11358' }
    let(:rap_sheet_with_eligibility) { double(has_three_convictions_of_same_type?: has_three_convictions_of_same_type?) }
    let(:result) { subject.has_two_prop_64_priors?(rap_sheet_with_eligibility) }

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
