class RapSheetWithEligibility < SimpleDelegator
  def counts
    eligible_events.flat_map(&:counts)
  end

  def eligible_events
    events_in_sf.map { |e| EventWithEligibility.new(e) }
  end

  def has_two_prior_convictions_of_same_type?(count)
    convictions.flat_map(&:counts).select do |c|
      c.code_section_starts_with([count.code_section]) && c.event.case_number != count.event.case_number
    end.select do |c|
      c.event.date <= count.event.date
    end.length >= 2
  end

  private

  def events_in_sf
    convictions.select do |e|
      if e.courthouse.include? 'SAN FRANCISCO'
        Rails.logger.tagged('UNEXPECTED INPUT') { Rails.logger.warn("Unknown Courthouse: #{e.courthouse}") }
      end

      e.courthouse.upcase.include? 'SAN FRANCISCO'
    end
  end
end
