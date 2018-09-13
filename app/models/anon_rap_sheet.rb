class AnonRapSheet < ApplicationRecord
  validates :county, :checksum, presence: true
  has_many :anon_cycles, dependent: :destroy
  has_one :rap_sheet_properties, dependent: :destroy

  def self.create_or_update(text:, county:, rap_sheet_with_eligibility:)
    checksum = Digest::SHA2.new.digest text

    existing_rap_sheet = AnonRapSheet.find_by(checksum: checksum)
    existing_rap_sheet.destroy! if existing_rap_sheet

    self.create_from_parser(rap_sheet_with_eligibility, county: county, checksum: checksum)
  end

  def self.create_from_parser(rap_sheet, county:, checksum:)
    cycles = rap_sheet.cycles.map do |cycle|
      AnonCycle.build_from_parser(cycle)
    end

    rap_sheet_properties = RapSheetProperties.build_from_eligibility(rap_sheet_with_eligibility: rap_sheet)

    AnonRapSheet.create!(
      checksum: checksum,
      county: county,
      year_of_birth: rap_sheet&.personal_info&.date_of_birth&.year,
      sex: rap_sheet&.personal_info&.sex,
      race: rap_sheet&.personal_info&.race,
      anon_cycles: cycles,
      person_unique_id: compute_person_unique_id(rap_sheet.personal_info),
      rap_sheet_properties: rap_sheet_properties
    )
  end

  private

  def self.compute_person_unique_id(personal_info)
    return unless personal_info
    Digest::SHA2.new.digest "#{personal_info.cii}#{personal_info.names[0]}#{personal_info.date_of_birth}"
  end
end
