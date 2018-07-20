class RapSheetWithEligibility < SimpleDelegator
  def eligible_events
    convictions.
      select { |e| in_sf?(e) }.
      reject(&:dismissed_by_pc1203?).
      map { |e| EventWithEligibility.new(e) }
  end

  def has_two_prior_convictions_of_same_type?(event, count)
    other_events = convictions.select { |e| e.case_number != event.case_number }

    other_events.select do |e|
      e.counts.any? do |c|
        c.code_section_starts_with([count.code_section])
      end
    end.length >= 2
  end

  def prop64_eligible(event, count)
    count.prop64_conviction? &&
      !count.ineligible_conviction? &&
      !has_two_prior_convictions_of_same_type?(event, count) &&
      !sex_offender_registration? &&
      !(superstrikes.length > 0)
  end

  private

  def in_sf?(e)
    sf_county_courthouses = ['CASC San Francisco', 'CASC San Francisco Co', 'CAMC San Francisco']
    sf_county_courthouses.include? e.courthouse
  end
end
