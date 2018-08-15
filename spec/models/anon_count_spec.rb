require 'rails_helper'

describe AnonCount do
  describe '#create_from_parser' do
    let(:anon_event) do
      anon_rap_sheet = AnonRapSheet.create!(county: 'san_francisco', checksum: Digest::SHA2.new.digest('foo'))
      anon_cycle = AnonCycle.create!(anon_rap_sheet: anon_rap_sheet)
      AnonEvent.create!(event_type: 'court', anon_cycle: anon_cycle)
    end

    it 'creates AnonCounts from parser output' do
      count = RapSheetParser::CourtCount.new(
        code_section_description: 'ARMED ROBBERY',
        severity: 'F',
        code: 'PC',
        section: '1505',
        disposition: RapSheetParser::Disposition.new(type: 'dismissed', sentence: nil)
      )

      described_class.create_from_parser(count, anon_event: anon_event)

      expect(AnonCount.count).to eq 1
      expect(AnonDisposition.count).to eq 1

      anon_count = AnonCount.first
      expect(anon_count.description).to eq 'ARMED ROBBERY'
      expect(anon_count.severity).to eq 'F'
      expect(anon_count.code).to eq 'PC'
      expect(anon_count.section).to eq '1505'
      expect(anon_count.anon_disposition.disposition_type).to eq 'dismissed'
      expect(anon_count.anon_disposition.sentence).to be_nil
    end
  end
end
