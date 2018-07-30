require 'rails_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/event_with_eligibility'
describe EventWithEligibility do
  describe 'remedy' do
    let (:event) do
      build_conviction_event(
        date: Date.today - 7.days,
        courthouse: 'CASC San Francisco',
        sentence: sentence,
      )
    end

    let (:event_with_eligibility) do
      described_class.new(event)
    end

    context 'when the sentence is still active' do
      let (:sentence) do
        RapSheetParser::ConvictionSentence.new(
          probation: 3.years
        )
      end
      it 'returns resentencing' do
        expect(event_with_eligibility.remedy).to eq 'resentencing'
      end

    end

    context 'when the sentence is not active' do
      let (:sentence) do
        RapSheetParser::ConvictionSentence.new(
          probation: 2.days
        )
      end
      it 'returns redesignation' do
        expect(event_with_eligibility.remedy).to eq 'redesignation'
      end
    end

    context 'when there is no sentence' do
      let((:sentence)) { nil }

      it 'returns redisgnation' do
        expect(event_with_eligibility.remedy).to eq 'redesignation'
      end
    end
  end

  describe 'potentially_eligible_counts' do
    let (:event) do
      prop64_eligible_count = build_court_count(code: 'HS', section: '11357')
      prop64_ineligible_count = build_court_count(code: 'HS', section: '12345')
      build_conviction_event(counts: [prop64_eligible_count, prop64_ineligible_count])
    end

    let (:event_with_eligibility) do
      described_class.new(event)
    end

    context 'when event has prop 64 eligible and ineligible counts' do
      it 'filters out counts that are not prop 64 convictions' do
        expect(event_with_eligibility.potentially_eligible_counts.length).to eq 1
        expect(event_with_eligibility.potentially_eligible_counts[0].section).to eq '11357'
      end
    end

  end
end
