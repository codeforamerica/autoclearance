require 'rails_helper'

describe AnonDisposition do
  describe '#build_from_parser' do
    it 'creates AnonDispositions from parser output' do
      disposition = RapSheetParser::Disposition.new(
        type: 'conviction',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 10.days),
        text: '*DISPO:CONVICTED'
      )
      anon_disposition = described_class.build_from_parser(disposition)
      expect(anon_disposition.disposition_type).to eq 'conviction'
      expect(anon_disposition.sentence).to eq '10d jail'
      expect(anon_disposition.text).to eq '*DISPO:CONVICTED'
    end

    it 'saves dispositions with no sentence' do
      disposition = RapSheetParser::Disposition.new(
        type: 'dismissed',
        sentence: nil,
        text: 'DISPO:DISMISSED/FURTHERANCE OF JUSTICE'
      )

      anon_disposition = described_class.build_from_parser(disposition)
      expect(anon_disposition.sentence).to be nil
      expect(anon_disposition.text).to eq 'DISPO:DISMISSED/FURTHERANCE OF JUSTICE'
    end
  end
end
