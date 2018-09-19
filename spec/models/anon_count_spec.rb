require 'rails_helper'

describe AnonCount do
  describe '#build_from_parser' do
    let(:event) { build_court_event(counts: [count]) }
    let(:rap_sheet) { build_rap_sheet(events: [event]) }
    let(:subject) do
      described_class.build_from_parser(
        index: 5,
        count: count,
        event: event,
        rap_sheet: rap_sheet
      )
    end

    context 'for a count with disposition convicted' do
      let(:count) do
        build_count(
          code_section_description: 'ARMED ROBBERY',
          code: 'HS',
          section: '11358',
          disposition: build_disposition(type: 'convicted', sentence: nil, text: 'DISPO:CONVICTED')
        )
      end

      it 'creates an anon count with associated count properties' do
        expect(subject.count_number).to eq 5
        expect(subject.description).to eq 'ARMED ROBBERY'
        expect(subject.code).to eq 'HS'
        expect(subject.section).to eq '11358'
        expect(subject.anon_disposition.disposition_type).to eq 'convicted'
        expect(subject.anon_disposition.sentence).to be_nil
        expect(subject.anon_disposition.text).to eq 'DISPO:CONVICTED'
        expect(subject.count_properties).to_not be_nil
        expect(subject.count_properties.has_prop_64_code).to eq true
      end
    end

    context 'for a count with disposition other than convicted' do
      let(:count) do
        build_count(
          code_section_description: 'ARMED ROBBERY',
          code: 'PC',
          section: '1505',
          disposition: build_disposition(type: 'dismissed', sentence: nil, text: 'DISPO:DISMISSED')
        )
      end
      it 'creates an AnonCount with no count_properties' do
        expect(subject.count_number).to eq 5
        expect(subject.description).to eq 'ARMED ROBBERY'
        expect(subject.code).to eq 'PC'
        expect(subject.section).to eq '1505'
        expect(subject.anon_disposition.disposition_type).to eq 'dismissed'
        expect(subject.anon_disposition.sentence).to be_nil
        expect(subject.anon_disposition.text).to eq 'DISPO:DISMISSED'
        expect(subject.count_properties).to be_nil
      end
    end

    context 'for a count with no disposition' do
      let(:count) do
        build_count(
          code_section_description: 'ARMED ROBBERY',
          code: 'PC',
          section: '1505',
          disposition: nil
        )
      end
      it 'creates an AnonCount with no disposition and no count_properties' do
        expect(subject.anon_disposition).to be_nil
        expect(subject.count_properties).to be_nil
      end
    end
  end
end
