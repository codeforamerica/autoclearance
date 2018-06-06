class CountWithEligibility < SimpleDelegator
  def prop64_eligible?
    code_section_starts_with(dismissible_codes)
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

  def code_section_starts_with(codes)
    codes.any? do |d|
      code_section.start_with? d
    end
  end

  def dismissible_codes
    [
      'HS 11357', #simple possession
      'HS 11358', #cultivation
      'HS 11359', #possession for sale
      'HS 11360', #transportation for sale
      'HS 11362.1'
    ]
  end
end