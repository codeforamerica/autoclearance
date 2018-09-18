require 'rails_helper'

describe CountWithEligibility do
  let(:count) { build_court_count(code: code, section: section) }

  subject { described_class.new(count) }

  describe '#potentially_eligible?' do
    let(:event) { EventWithEligibility.new(build_court_event) }
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
          allow(PleaBargainClassifier).to receive(:new)
            .with(event: event, count: subject)
            .and_return(plea_bargain_classifier)
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
          allow(PleaBargainClassifier).to receive(:new)
            .with(event: event, count: subject)
            .and_return(plea_bargain_classifier)
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

      event = build_court_event(
        date: Time.zone.today - 7.days,
        case_number: '1',
        counts: [eligible_count]
      )

      rap_sheet = build_rap_sheet(events: ([event]))
      eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

      expect(described_class.new(eligible_count).csv_eligibility_column(EventWithEligibility.new(event), eligibility)).to eq 'yes'
    end

    it 'returns false if rap sheet level disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_court_event(counts: [eligible_count])

      eligibility = double(disqualifiers?: true)

      expect(described_class.new(eligible_count).csv_eligibility_column(EventWithEligibility.new(event), eligibility)).to eq 'no'
    end

    context 'plea bargain detection' do
      let(:code) {}
      let(:section) {}

      it 'returns true if plea bargain' do
        eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet)
        event = EventWithEligibility.new(build_court_event)
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: true, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new)
          .with(event: event, count: subject)
          .and_return(plea_bargain_classifier)

        expect(subject.csv_eligibility_column(event, eligibility)).to eq('yes')
      end

      it 'returns "maybe" if possible plea bargain only' do
        eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet)
        event = EventWithEligibility.new(build_court_event)
        plea_bargain_classifier = instance_double(PleaBargainClassifier, plea_bargain?: false, possible_plea_bargain?: true)
        allow(PleaBargainClassifier).to receive(:new)
          .with(event: event, count: subject)
          .and_return(plea_bargain_classifier)

        expect(subject.csv_eligibility_column(event, eligibility)).to eq('maybe')
      end
    end
  end
  describe '#has_two_prop_64_priors?' do
    let(:count) { build_court_count(code: 'HS', section: '11358') }
    let(:event) { build_court_event(counts: [count]) }
    let(:rap_sheet_with_eligibility) { build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet(events: events)) }
    let(:result) { CountWithEligibility.new(count).has_two_prop_64_priors?(rap_sheet_with_eligibility) }

    context 'if there are fewer than 3 of a prop-64 two-priors relevant code' do
      let(:events) { [event, event] }

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'if there 3 or more of a prop-64 two-priors relevant code' do
      let(:events) { [event, event, event] }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'if there 3 or more of a non-relevant code' do
      let(:count) { build_court_count(code: 'HS', section: '11357') }
      let(:events) { [event, event, event] }

      it 'returns false' do
        expect(result).to be false
      end
    end
  end

  describe '#eligible?' do
    it 'returns true if prop64 conviction and no disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11357')

      event = build_court_event(
        date: Time.zone.today - 7.days,
        case_number: '1',
        counts: [eligible_count]
      )

      rap_sheet = build_rap_sheet(events: ([event]))
      eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

      expect(described_class.new(eligible_count).eligible?(EventWithEligibility.new(event), eligibility)).to eq true
    end

    it 'returns false if rap sheet level disqualifiers' do
      eligible_count = build_court_count(code: 'HS', section: '11358')

      event = build_court_event(counts: [eligible_count])

      eligibility = double(disqualifiers?: true)

      expect(described_class.new(eligible_count).eligible?(EventWithEligibility.new(event), eligibility)).to eq false
    end

    it 'returns false if it has 2 prop 64 priors' do
      eligible_count = build_court_count(code: 'HS', section: '11358')

      event = build_court_event(counts: [eligible_count])

      eligibility = double(has_three_convictions_of_same_type?: true, disqualifiers?: false)

      expect(described_class.new(eligible_count).eligible?(EventWithEligibility.new(event), eligibility)).to eq false
    end

    it 'returns true if possible plea bargain' do
      eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet)
      event = EventWithEligibility.new(build_court_event)
      count = described_class.new(build_court_count(code: 'PC', section: '32'))

      plea_bargain_classifier = instance_double(PleaBargainClassifier, possible_plea_bargain?: true)
      allow(PleaBargainClassifier).to receive(:new)
        .with(event: event, count: count)
        .and_return(plea_bargain_classifier)

      expect(count.eligible?(event, eligibility)).to eq(true)
    end

    it 'returns false if no code section' do
      event = build_court_event
      eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet(events: [event]))
      count = described_class.new(build_court_count(code: nil, section: nil))

      expect(count.eligible?(EventWithEligibility.new(event), eligibility)).to eq(false)
    end
  end
end
