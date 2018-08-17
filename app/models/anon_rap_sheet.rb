class AnonRapSheet < ApplicationRecord
  validates_presence_of :county, :checksum
  has_many :anon_cycles, dependent: :destroy

  def self.create_or_update(text:, county:, rap_sheet:)
    checksum = Digest::SHA2.new.digest text

    existing_rap_sheet = AnonRapSheet.find_by(checksum: checksum)
    existing_rap_sheet.destroy! if existing_rap_sheet

    self.create_from_parser(rap_sheet, county: county, checksum: checksum)
  end

  def self.create_from_parser(rap_sheet, county:, checksum:)
    cycles = rap_sheet.cycles.map do |cycle|
      AnonCycle.build_from_parser(cycle)
    end

    AnonRapSheet.create!(
      checksum: checksum,
      county: county,
      year_of_birth: rap_sheet&.personal_info&.date_of_birth&.year,
      sex: rap_sheet&.personal_info&.sex,
      race: rap_sheet&.personal_info&.race,
      anon_cycles: cycles,
      person_unique_id: compute_person_unique_id(rap_sheet.personal_info)
    )
  end

  private

  def self.compute_person_unique_id(personal_info)
    return unless personal_info
    Digest::SHA2.new.digest "#{personal_info.cii}#{personal_info.names[0]}#{personal_info.date_of_birth}"
  end
end
