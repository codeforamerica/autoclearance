require 'spec_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/count_with_eligibility'

describe CountWithEligibility do
  let(:count) do
    RapSheetParser::ConvictionCount.new(
      event: nil,
      code_section_description: 'foo',
      severity: 'F',
      code: code,
      section: section
    )
  end

  subject { described_class.new(count) }

  describe '#prop64_eligible' do
    context 'when the count is an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359' }
      it 'returns true' do
        expect(subject).to be_prop64_eligible
      end
    end

    context 'when the count is a subsection of an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359(a)' }
      it 'returns true' do
        expect(subject).to be_prop64_eligible
      end
    end

    context 'when the count is an ineligible code' do
      let(:code) { 'HS' }
      let(:section) { '12345' }
      it 'returns false' do
        expect(subject).not_to be_prop64_eligible
      end
    end

  end
end
