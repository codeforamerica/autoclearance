class CountProperties < ApplicationRecord
  belongs_to :anon_count
  has_one :eligibility_estimate, dependent: :destroy

  def self.build(count:, rap_sheet:, event:)
    rap_sheet_with_eligibility = RapSheetWithEligibility.new(
      rap_sheet: rap_sheet,
      courthouses: [],
      logger: Logger.new('/dev/null')
    )
    event_with_eligibility = EventWithEligibility.new(event)
    count_with_eligibility = CountWithEligibility.new(count: count, event: event_with_eligibility)
    CountProperties.new(
      has_prop_64_code: count_with_eligibility.prop64_conviction?,
      has_two_prop_64_priors: count_with_eligibility.has_two_prop_64_priors?(rap_sheet_with_eligibility),
      prop_64_plea_bargain: count_with_eligibility.plea_bargain,
      eligibility_estimate: eligibility_estimate(
        count_with_eligibility: count_with_eligibility,
        rap_sheet_with_eligibility: rap_sheet_with_eligibility
      )
    )
  end

  def self.eligibility_estimate(count_with_eligibility:, rap_sheet_with_eligibility:)
    EligibilityEstimate.build(
      count_with_eligibility: count_with_eligibility,
      rap_sheet_with_eligibility: rap_sheet_with_eligibility
    )
  end
end
