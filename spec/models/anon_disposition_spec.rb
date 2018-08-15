require 'rails_helper'

describe AnonDisposition do
  describe '#build_from_parser' do
    it 'creates AnonDispositions from parser output' do
      disposition = RapSheetParser::Disposition.new(
        type: 'conviction',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 10.days)
      )
      anon_disposition = described_class.build_from_parser(disposition)
      expect(anon_disposition.disposition_type).to eq 'conviction'
      expect(anon_disposition.sentence).to eq '10d jail'
    end

    it 'saves dispositions with no sentence' do
      disposition = RapSheetParser::Disposition.new(
        type: 'dismissed',
        sentence: nil
      )

      anon_disposition = described_class.build_from_parser(disposition)
      expect(anon_disposition.sentence).to be nil
    end
  end
end
