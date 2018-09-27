class CountProperties < ApplicationRecord
  belongs_to :anon_count
  has_one :eligibility_estimate, dependent: :destroy

  def self.build(count:, rap_sheet:, event:)
    rap_sheet_with_eligibility = RapSheetWithEligibility.new(
      rap_sheet: rap_sheet,
      county: { courthouses: [] },
      logger: Logger.new('/dev/null')
    )
    event_with_eligibility = EventWithEligibility.new(
      event: event,
      eligibility: rap_sheet_with_eligibility
    )
    prop64_classifier = Prop64Classifier.new(
      count: count,
      event: event_with_eligibility,
      eligibility: rap_sheet_with_eligibility
    )
    CountProperties.new(
      has_prop_64_code: prop64_classifier.prop64_conviction?,
      has_two_prop_64_priors: prop64_classifier.has_two_prop_64_priors?,
      prop_64_plea_bargain: prop64_classifier.plea_bargain,
      eligibility_estimate: EligibilityEstimate.build(prop64_classifier)
    )
  end
end
