class CountWithEligibility < SimpleDelegator
  def prop64_conviction?
    code_section_starts_with(dismissible_codes) && !code_section_starts_with(ineligible_codes)
  end

  def needs_info_under_18?
    code_section_starts_with(['HS 11359', 'HS 11360'])
  end

  def needs_info_under_21?
    code_section_starts_with(['HS 11359'])
  end
  
  def needs_info_across_state_lines?
    code_section_starts_with(['HS 11360'])
  end

  private

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
