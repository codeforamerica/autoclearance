class RapSheetWithEligibility < SimpleDelegator
  def counts
    eligible_events.flat_map(&:counts)
  end

  def eligible_events
    convictions.
      select { |e| in_sf?(e) }.
      reject(&:dismissed_by_pc1203?).
      map { |e| EventWithEligibility.new(e) }
  end

  def has_two_prior_convictions_of_same_type?(count)
    convictions.flat_map(&:counts).select do |c|
      c.code_section_starts_with([count.code_section]) && c.event.case_number != count.event.case_number
    end.select do |c|
      c.event.date <= count.event.date
    end.length >= 2
  end

  private

  def in_sf?(e)
    if e.courthouse.include? 'SAN FRANCISCO'
      Rails.logger.tagged('UNEXPECTED INPUT') { Rails.logger.warn("Unknown Courthouse: #{e.courthouse}") }
    end
    sf_county_courthouses = ['CASC San Francisco', 'CASC San Francisco Co', 'CAMC San Francisco']
    sf_county_courthouses.include? e.courthouse
  end
end
