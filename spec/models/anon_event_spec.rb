require 'rails_helper'

describe AnonEvent do
  describe '#build_from_parser' do
    it 'creates from parser output' do
      count_1 = build_court_count(
        code: 'PC',
        section: '456'
      )
      
      count_2 = build_court_count(
        code: 'PC',
        section: '789'
      )

      event = build_court_event(
        date: Date.new(1991, 1, 5),
        courthouse: 'Some courthouse',
        counts: [count_1, count_2],
        updates: [],
        name_code: nil,
      )

      anon_event = described_class.build_from_parser(event)
      counts = anon_event.anon_counts

      expect(anon_event.agency).to eq 'Some courthouse'
      expect(anon_event.date).to eq Date.new(1991, 1, 5)
      expect(counts[0].code).to eq 'PC'
      expect(counts[0].section).to eq '456'
      expect(counts[0].count_number).to eq 1
      expect(counts[1].code).to eq 'PC'
      expect(counts[1].section).to eq '789'
      expect(counts[1].count_number).to eq 2
    end
  end
end
