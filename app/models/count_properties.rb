class CountProperties < ApplicationRecord
  belongs_to :anon_count

  def self.build(count:, rap_sheet:, event:)
    rap_sheet_with_eligibility = RapSheetWithEligibility.new(
      rap_sheet: rap_sheet,
      courthouses: [],
      logger: Logger.new('/dev/null')
    )
    event_with_eligibility = EventWithEligibility.new(event)
    count_with_eligibility = CountWithEligibility.new(count)
    CountProperties.new(
      has_prop_64_code: count_with_eligibility.prop64_conviction?,
      has_two_prop_64_priors: count_with_eligibility.has_two_prop_64_priors?(rap_sheet_with_eligibility),
      prop_64_plea_bargain: count_with_eligibility.is_plea_bargain(event_with_eligibility)
    )
  end
end