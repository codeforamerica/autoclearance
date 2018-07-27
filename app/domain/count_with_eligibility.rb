class CountWithEligibility < SimpleDelegator
  def prop64_conviction_or_possible_bargain?(event)
    prop64_conviction? || possibly_plea_bargained_prop64_related_conviction?(event)
  end

  def prop64_conviction?
    code_section_starts_with(dismissible_codes) && !code_section_starts_with(ineligible_codes)
  end

  def prop64_eligible(event, eligibility)
    if likely_plea_bargained_prop64_related_conviction?(event)
      return true
    elsif possibly_plea_bargained_prop64_related_conviction?(event)
      return 'maybe'
    end

    prop64_conviction? &&
      !eligibility.has_two_prior_convictions_of_same_type?(event, self) &&
      !eligibility.sex_offender_registration? &&
      !(eligibility.superstrikes.length > 0)
  end

  private

  def prop64_conviction_or_likely_bargain?(event)
    prop64_conviction? || likely_plea_bargained_prop64_related_conviction?(event)
  end

  def possibly_plea_bargained_prop64_related_conviction?(event)
    code_section_starts_with(possible_plea_bargain_codes) && distinct_code_sections_in_cycle_include_dismissible_codes(event)
  end

  def likely_plea_bargained_prop64_related_conviction?(event)
    code_section_starts_with(possible_plea_bargain_codes) && distinct_code_sections_in_cycle_are_only(event, dismissible_codes + possible_plea_bargain_codes)
  end

  def distinct_code_sections_in_cycle_are_only(event, codes)
    undismissed_counts_for_event_cycle(event).all? do |count|
      count.code_section_starts_with(codes)
    end
  end

  def distinct_code_sections_in_cycle_include_dismissible_codes(event)
    undismissed_counts_for_event_cycle(event).any?(&:prop64_conviction?)
  end

  def undismissed_counts_for_event_cycle(event)
    event.cycle_events.flat_map do |event|
      event.counts.reject do |count|
        count.disposition == 'prosecutor_rejected'
      end
    end
  end

  def possible_plea_bargain_codes
    [
      'PC 32',
      'HS 11364'
    ]
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
