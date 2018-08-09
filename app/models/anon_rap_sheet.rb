class AnonRapSheet < ApplicationRecord
  validates_presence_of :county, :checksum
  has_many :anon_events
  
  def self.create_from_parser(text:, county:, rap_sheet:)
    checksum = Digest::SHA2.new.digest text
    if AnonRapSheet.find_by(checksum: checksum).nil?
      events = rap_sheet.convictions.map do |event|
        AnonEvent.build_from_parser(event)
      end
      
      AnonRapSheet.create!(
        checksum: checksum,
        county: county,
        anon_events: events
      )
    end
  end
end
