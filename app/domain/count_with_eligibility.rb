class CountWithEligibility < SimpleDelegator
  attr_reader :event, :eligibility

  def initialize(count:, event:, eligibility:)
    super(count)
    @event = event
    @eligibility = eligibility
  end

  def potentially_eligible?
    prop64_conviction? || plea_bargain_classifier.possible_plea_bargain?
  end

  def prop64_conviction?
    subsection_of?(dismissible_codes) && !subsection_of?(ineligible_codes)
  end

  def eligible?
    return 'no' unless potentially_eligible? && !has_disqualifiers? && !has_two_prop_64_priors?
    return 'yes' if plea_bargain_classifier.plea_bargain?
    return 'maybe' if plea_bargain_classifier.possible_plea_bargain?
    'yes'
  end

  def has_two_prop_64_priors?
    two_priors_codes = ['HS 11358', 'HS 11359', 'HS 11360']
    two_priors_codes.include?(code_section) && eligibility.has_three_convictions_of_same_type?(code_section)
  end

  def plea_bargain
    return 'yes' if plea_bargain_classifier.plea_bargain?
    return 'maybe' if plea_bargain_classifier.possible_plea_bargain?
    'no'
  end

  private

  def plea_bargain_classifier
    PleaBargainClassifier.new(self)
  end

  def has_disqualifiers?
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
