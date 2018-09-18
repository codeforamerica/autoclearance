class EligibilityEstimate < ApplicationRecord
  belongs_to :count_properties

  def self.build(
    event_with_eligibility:,
    count_with_eligibility:,
    rap_sheet_with_eligibility:
  )
    prop_64_eligible = count_with_eligibility.csv_eligibility_column(
      event_with_eligibility,
      rap_sheet_with_eligibility
    )
    EligibilityEstimate.new(prop_64_eligible: prop_64_eligible)
  end
end
