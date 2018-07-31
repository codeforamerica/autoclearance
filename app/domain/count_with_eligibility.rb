class CountWithEligibility < SimpleDelegator
  def potentially_eligible?(event)
    prop64_conviction? || plea_bargain_classifier(event).possible_plea_bargain?
  end

  def prop64_conviction?
    code_section_starts_with(dismissible_codes) && !code_section_starts_with(ineligible_codes)
  end

  def csv_eligibility_column(event, eligibility)
    return false if has_disqualifiers?(event, eligibility)

    if plea_bargain_classifier(event).plea_bargain?
      true
    elsif prop64_conviction?
      true
    elsif plea_bargain_classifier(event).possible_plea_bargain?
      'maybe'
    end
  end

  def eligible?(event, eligibility)
    prop64_conviction? && !has_disqualifiers?(event, eligibility)
  end

  private

  def plea_bargain_classifier(event)
    PleaBargainClassifier.new(event: event, count: self)
  end
  
  def has_disqualifiers?(event, eligibility)
    eligibility.has_two_prior_convictions_of_same_type?(event, self) ||
      eligibility.sex_offender_registration? ||
      eligibility.superstrikes.any?
  end

  def dismissible_codes
    [
      'HS 11357', #simple possession
      'HS 11358', #cultivation
      'HS 11359', #possession for sale
      'HS 11360', #transportation for sale
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
