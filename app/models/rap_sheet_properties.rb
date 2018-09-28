class RapSheetProperties < ApplicationRecord
  belongs_to :anon_rap_sheet

  def self.build(rap_sheet:)
    RapSheetProperties.new(
      has_superstrikes: rap_sheet.superstrikes.present?,
      has_sex_offender_registration: rap_sheet.sex_offender_registration?,
      deceased: rap_sheet.deceased_events.any?
    )
  end
end
