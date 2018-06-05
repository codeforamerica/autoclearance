class CountWithEligibility < SimpleDelegator
  def prop64_eligible?
    dismissible_codes.any? do |d|
      code_section.start_with? d
    end
  end

  private

  def dismissible_codes
    [
      'HS 11357',
      'HS 11358',
      'HS 11359',
      'HS 11360',
      'HS 11362.1'
    ]
  end
end
