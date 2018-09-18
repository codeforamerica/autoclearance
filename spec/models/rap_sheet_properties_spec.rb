require 'rails_helper'

describe RapSheetProperties do
  describe '#build_from_eligibility' do
    let(:subject) { RapSheetProperties.build(rap_sheet: rap_sheet) }

    let(:rap_sheet) do
      build_rap_sheet(events: events)
    end

    let(:events) {
      [
        build_court_event(counts: [build_court_count(code: 'HS', section: '11358')]),
        event
      ]
    }

    context 'when there are no superstrikes, deceased events, or sex offender registration' do
      let(:event) { build_court_event }

      it 'creates RapSheetProperties with superstrikes false' do
        expect(subject.has_superstrikes).to eq false
        expect(subject.deceased).to eq false
        expect(subject.has_sex_offender_registration).to eq false
      end
    end

    context 'when there are superstrikes' do
      let(:event) { build_court_event(counts: [build_court_count(code:'PC', section: '187')]) }

      it 'creates RapSheetProperties with superstrikes true' do
        expect(subject.has_superstrikes).to eq true
      end
    end

    context 'when there is a deceased event' do
      let(:event) { build_other_event(header: 'deceased') }

      it 'creates RapSheetProperties deceased true' do
        expect(subject.deceased).to eq true
      end
    end

    context 'when there is a sex offense registration' do
      let(:event) { build_other_event(header: 'registration', counts: [build_court_count(code: 'PC', section: '290')]) }

      it 'creates RapSheetProperties with sex offender registration true' do
        expect(subject.has_sex_offender_registration).to eq true
      end
    end
  end
end
