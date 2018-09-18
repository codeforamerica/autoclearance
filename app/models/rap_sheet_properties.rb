class RapSheetProperties < ApplicationRecord
  belongs_to :anon_rap_sheet

  def self.build(rap_sheet:)
    rap_sheet_with_eligibility = RapSheetWithEligibility.new(
      rap_sheet: rap_sheet,
      courthouses: [],
      logger: Logger.new('/dev/null')
    )

    RapSheetProperties.new(
      has_superstrikes: rap_sheet_with_eligibility.superstrikes.present?,
      has_sex_offender_registration: rap_sheet_with_eligibility.sex_offender_registration?,
      deceased: rap_sheet_with_eligibility.has_deceased_event?
    )
  end
end
