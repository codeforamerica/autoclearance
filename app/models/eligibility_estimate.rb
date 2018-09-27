class EligibilityEstimate < ApplicationRecord
  belongs_to :count_properties

  def self.build(prop64_classifier)
    prop_64_eligible = prop64_classifier.eligible?
    EligibilityEstimate.new(prop_64_eligible: prop_64_eligible)
  end
end
