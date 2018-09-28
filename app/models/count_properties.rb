class CountProperties < ApplicationRecord
  belongs_to :anon_count
  has_one :eligibility_estimate, dependent: :destroy

  def self.build(count:, rap_sheet:, event:)
    prop64_classifier = Prop64Classifier.new(
      count: count,
      event: event,
      rap_sheet: rap_sheet,
      county: { }
    )
    CountProperties.new(
      has_prop_64_code: prop64_classifier.prop64_conviction?,
      has_two_prop_64_priors: prop64_classifier.has_two_prop_64_priors?,
      prop_64_plea_bargain: prop64_classifier.plea_bargain,
      eligibility_estimate: EligibilityEstimate.build(prop64_classifier)
    )
  end
end
