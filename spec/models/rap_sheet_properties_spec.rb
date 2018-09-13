require 'rails_helper'

describe RapSheetProperties do
  describe '#build_from_eligibility' do
    let(:subject) { RapSheetProperties.build_from_eligibility(rap_sheet_with_eligibility: rap_sheet_with_eligibility) }

    let(:rap_sheet_with_eligibility) do
      double('rap_sheet_with_eligibility',
             has_deceased_event?: has_deceased,
             sex_offender_registration?: has_sex_offense,
             superstrikes: superstrikes)
    end

    let(:superstrikes) { [] }
    let(:has_deceased) { false }
    let(:has_sex_offense) { false }

    context 'when there are no superstrikes' do
      let(:superstrikes) { [] }

      it 'creates RapSheetProperties with superstrikes false' do
        expect(subject.has_superstrikes).to eq false
      end
    end

    context 'when there are superstrikes' do
      let(:superstrikes) { ['PC 187'] }

      it 'creates RapSheetProperties with superstrikes true' do
        expect(subject.has_superstrikes).to eq true
      end
    end

    context 'when there is a deceased event' do
      let(:has_deceased) { true }

      it 'creates RapSheetProperties deceased true' do
        expect(subject.deceased).to eq true
      end
    end

    context 'when there is no deceased event' do
      let(:has_deceased) { false }

      it 'creates RapSheetProperties deceased false' do
        expect(subject.deceased).to eq false
      end
    end

    context 'when there is a sex offense registration' do
      let(:has_sex_offense) { true }

      it 'creates RapSheetProperties with sex offender registration true' do
        expect(subject.has_sex_offender_registration).to eq true
      end
    end

    context 'when there is no sex offense registration' do
      let(:has_sex_offense) { false }

      it 'creates RapSheetProperties with sex offender registration false' do
        expect(subject.has_sex_offender_registration).to eq false
      end
    end
  end
end
