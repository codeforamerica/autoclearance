require 'rails_helper'

describe AnonEvent do
  describe '#create_from_parser' do
    it 'creates from parser output' do
      count_1 = build_court_count(
        code: 'PC',
        section: '456'
      )

      event = build_court_event(
        date: Date.new(1991, 1, 5),
        courthouse: 'Some courthouse',
        sentence: RapSheetParser::ConvictionSentence.new(probation: 1.year),
        counts: [count_1],
        updates: [],
        name_code: nil
      )

      anon_event = described_class.create_from_parser(event)
      counts = anon_event.anon_counts

      expect(anon_event.agency).to eq 'Some courthouse'
      expect(anon_event.date).to eq Date.new(1991, 1, 5)
      expect(counts[0].code).to eq 'PC'
      expect(counts[0].section).to eq '456'
    end
  end
end
