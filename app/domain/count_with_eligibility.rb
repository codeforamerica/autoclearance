class CountWithEligibility < SimpleDelegator
  def potentially_eligible?(event)
    prop64_conviction? || plea_bargain_classifier(event).possible_plea_bargain?
  end

  def prop64_conviction?
    subsection_of?(dismissible_codes) && !subsection_of?(ineligible_codes)
  end

  def csv_eligibility_column(event, eligibility)
    return false unless eligible?(event, eligibility)
    return true if plea_bargain_classifier(event).plea_bargain?
    return 'maybe' if plea_bargain_classifier(event).possible_plea_bargain?
    true
  end

  def eligible?(event, eligibility)
    potentially_eligible?(event) && !has_disqualifiers?(eligibility) && !has_2_prop_64_priors?(eligibility)
  end

  def has_2_prop_64_priors?(eligibility)
    two_priors_codes = ['HS 11358', 'HS 11359', 'HS 11360']
    two_priors_codes.include?(code_section) && eligibility.has_three_convictions_of_same_type?(code_section)
  end

  private

  def plea_bargain_classifier(event)
    PleaBargainClassifier.new(event: event, count: self)
  end

  def has_disqualifiers?(eligibility)
    eligibility.disqualifiers?
  end

  def dismissible_codes
    [
      'HS 11357', # simple possession
      'HS 11358', # cultivation
      'HS 11359', # possession for sale
      'HS 11360', # transportation for sale
    ]
  end

  def ineligible_codes
    [
      'HS 11359(c)(3)',
      'HS 11359(d)',
      'HS 11360(a)(3)(c)',
      'HS 11360(a)(3)(d)'
    ]
  end
end
