require 'rails_helper'

describe AnonDisposition do
  describe '#create_from_parser' do
    let(:anon_count) do
      anon_rap_sheet = AnonRapSheet.create!(county: 'san_francisco', checksum: Digest::SHA2.new.digest('foo'))
      anon_cycle = AnonCycle.create!(anon_rap_sheet: anon_rap_sheet)
      anon_event = AnonEvent.create!(event_type: 'court', anon_cycle: anon_cycle)
      AnonCount.create!(anon_event: anon_event)
    end

    it 'creates AnonDispositions from parser output' do
      disposition = RapSheetParser::Disposition.new(
        type: 'conviction',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 10.days)
      )
      anon_disposition = described_class.create_from_parser(disposition, anon_count: anon_count)

      expect(AnonDisposition.count).to eq 1

      expect(anon_disposition.disposition_type).to eq 'conviction'
      expect(anon_disposition.sentence).to eq '10d jail'
      expect(anon_disposition.anon_count).to eq anon_count
    end

    it 'saves dispositions with no sentence' do
      disposition = RapSheetParser::Disposition.new(
        type: 'dismissed',
        sentence: nil
      )

      anon_disposition = described_class.create_from_parser(disposition, anon_count: anon_count)
      expect(AnonDisposition.count).to eq 1
      expect(anon_disposition.sentence).to be nil
    end
  end
end
