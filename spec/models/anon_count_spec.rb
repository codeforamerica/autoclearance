require 'rails_helper'

describe AnonCount do
  describe '#build_from_parser' do
    it 'creates AnonCounts from parser output' do
      count = RapSheetParser::CourtCount.new(
        code_section_description: 'ARMED ROBBERY',
        severity: 'F',
        code: 'PC',
        section: '1505',
        disposition: RapSheetParser::Disposition.new(type: 'dismissed', sentence: nil)
      )

      anon_count = described_class.build_from_parser(count, 5)
      expect(anon_count.count_number).to eq 5
      expect(anon_count.description).to eq 'ARMED ROBBERY'
      expect(anon_count.severity).to eq 'F'
      expect(anon_count.code).to eq 'PC'
      expect(anon_count.section).to eq '1505'
      expect(anon_count.anon_disposition.disposition_type).to eq 'dismissed'
      expect(anon_count.anon_disposition.sentence).to be_nil
    end
  end
end
