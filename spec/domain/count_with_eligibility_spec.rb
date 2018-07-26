require 'rails_helper'

describe CountWithEligibility do
  let(:count) { build_court_count(code: code, section: section) }

  subject { described_class.new(count) }

  describe '#prop64_conviction?' do
    context 'when the count is an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359' }
      it 'returns true' do
        expect(subject).to be_prop64_conviction
      end
    end

    context 'when the count is a subsection of an eligible code' do
      let(:code) { 'HS' }
      let(:section) { '11359(a)' }
      it 'returns true' do
        expect(subject).to be_prop64_conviction
      end
    end

    context 'when the count is an ineligible code' do
      let(:code) { 'HS' }
      let(:section) { '12345' }
      it 'returns false' do
        expect(subject).not_to be_prop64_conviction
      end
    end

    context 'when the count is an ineligible subsection' do
      let(:code) { 'HS' }
      let(:section) { '11359(d)' }
      it 'returns false' do
        expect(subject).not_to be_prop64_conviction
      end
    end
  end
end
