class AnonRapSheet < ApplicationRecord
  validates_presence_of :county, :checksum
  has_many :anon_events, dependent: :destroy

  def self.create_or_update(text:, county:, rap_sheet:)
    checksum = Digest::SHA2.new.digest text

    existing_rap_sheet = AnonRapSheet.find_by(checksum: checksum)
    existing_rap_sheet.destroy! if existing_rap_sheet

    self.create_from_parser(rap_sheet, county: county, checksum: checksum)
  end

  def self.create_from_parser(rap_sheet, county:, checksum:)
    anon_rap_sheet = AnonRapSheet.create!(
      checksum: checksum,
      county: county
    )

    rap_sheet.convictions.map do |event|
      AnonEvent.create_from_parser(event, anon_rap_sheet: anon_rap_sheet)
    end

    anon_rap_sheet
  end
end
