require 'rails_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/event_with_eligibility'
describe EventWithEligibility do
  let(:rap_sheet_with_eligibility) { build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet) }
  subject { described_class.new(event: event, eligibility: rap_sheet_with_eligibility) }

  describe 'remedy' do
    let(:event) do
      build_court_event(
        date: Time.zone.today - 7.days,
        courthouse: 'CASC San Francisco',
        counts: [build_count(disposition: build_disposition(sentence: sentence))]
      )
    end

    context 'when the sentence is still active' do
      let(:sentence) do
        RapSheetParser::ConvictionSentence.new(probation: 3.years)
      end

      it 'returns resentencing' do
        expect(subject.remedy).to eq 'resentencing'
      end
    end

    context 'when the sentence is not active' do
      let(:sentence) do
        RapSheetParser::ConvictionSentence.new(probation: 2.days)
      end

      it 'returns redesignation' do
        expect(subject.remedy).to eq 'redesignation'
      end
    end

    context 'when there is no sentence' do
      let(:sentence) { nil }

      it 'returns redisgnation' do
        expect(subject.remedy).to eq 'redesignation'
      end
    end
  end

  describe 'potentially_eligible_counts' do
    context 'when event has prop 64 eligible and ineligible counts' do
      let(:event) do
        prop64_eligible_count = build_count(code: 'HS', section: '11357')
        prop64_ineligible_count = build_count(code: 'HS', section: '12345')
        build_court_event(counts: [prop64_eligible_count, prop64_ineligible_count])
      end

      it 'filters out counts that are not prop 64 convictions' do
        expect(subject.potentially_eligible_counts.length).to eq 1
        expect(subject.potentially_eligible_counts[0].code_section).to eq 'HS 11357'
      end
    end

    context 'there are dismissed counts' do
      let(:event) do
        prop64_eligible_count = build_count(code: 'HS', section: '11357', disposition: build_disposition(type: 'convicted'))
        prop64_ineligible_count = build_count(code: 'HS', section: '11360', disposition: build_disposition(type: 'dismissed'))
        build_court_event(counts: [prop64_eligible_count, prop64_ineligible_count])
      end

      it 'filters out counts without convictions' do
        expect(subject.potentially_eligible_counts.length).to eq 1
        expect(subject.potentially_eligible_counts[0].code_section).to eq 'HS 11357'
      end
    end
  end

  describe 'eligible_counts' do
    let(:eligible_counts) { subject.eligible_counts }

    context 'when event has prop 64 eligible and ineligible counts' do
      let(:event) do
        prop64_eligible_count = build_count(code: 'HS', section: '11357')
        prop64_ineligible_count = build_count(code: 'HS', section: '12345')
        build_court_event(counts: [prop64_eligible_count, prop64_ineligible_count])
      end

      it 'filters out counts that are not prop 64 convictions' do
        expect(eligible_counts.length).to eq 1
        expect(eligible_counts[0].code_section).to eq 'HS 11357'
      end
    end

    context 'there are dismissed counts' do
      let(:event) do
        prop64_eligible_count = build_count(code: 'HS', section: '11357', disposition: build_disposition(type: 'convicted'))
        prop64_ineligible_count = build_count(code: 'HS', section: '11360', disposition: build_disposition(type: 'dismissed'))
        build_court_event(counts: [prop64_eligible_count, prop64_ineligible_count])
      end

      it 'filters out counts without convictions' do
        expect(eligible_counts.length).to eq 1
        expect(eligible_counts[0].code_section).to eq 'HS 11357'
      end
    end
  end
end
