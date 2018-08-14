require 'rails_helper'

describe AnonEvent do
  describe '#create_from_parser' do
    it 'creates from parser output' do
      anon_rap_sheet = AnonRapSheet.create!(county: 'san_francisco', checksum: Digest::SHA2.new.digest('foo'))

      count_1 = build_court_count(
        code: 'PC',
        section: '456'
      )

      event = build_court_event(
        date: Date.new(1991, 1, 5),
        courthouse: 'Some courthouse',
        counts: [count_1],
        updates: [],
        name_code: nil,
      )

      anon_event = described_class.create_from_parser(event, anon_rap_sheet: anon_rap_sheet)
      counts = anon_event.anon_counts

      expect(anon_event.agency).to eq 'Some courthouse'
      expect(anon_event.date).to eq Date.new(1991, 1, 5)
      expect(anon_event.anon_rap_sheet).to eq anon_rap_sheet
      expect(counts[0].code).to eq 'PC'
      expect(counts[0].section).to eq '456'
    end
  end
end
