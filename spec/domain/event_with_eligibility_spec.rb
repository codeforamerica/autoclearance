require 'spec_helper'
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
end
