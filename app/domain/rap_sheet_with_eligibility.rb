class RapSheetWithEligibility < SimpleDelegator
  def eligible_events
    convictions.
      select { |e| in_sf?(e) }.
      reject(&:dismissed_by_pc1203?).
      map { |e| EventWithEligibility.new(e) }
  end

  def has_two_prior_convictions_of_same_type?(event, count)
    events_in_past = convictions.select { |e| e.date <= event.date }

    events_in_past.flat_map do |e|
      e.counts.select do |c|
        c.code_section_starts_with([count.code_section]) && e.case_number != event.case_number
      end
    end.length >= 2
  end

  def prop64_eligible(event, count)
    has_disqualifiers = count.ineligible_conviction? || has_two_prior_convictions_of_same_type?(event,count) || sex_offender_registration? || superstrikes.length > 0

    count.prop64_conviction? && !has_disqualifiers
  end

  private

  def in_sf?(e)
    sf_county_courthouses = ['CASC San Francisco', 'CASC San Francisco Co', 'CAMC San Francisco']
    sf_county_courthouses.include? e.courthouse
  end
end
