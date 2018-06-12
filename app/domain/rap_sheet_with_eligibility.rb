class RapSheetWithEligibility < SimpleDelegator
  def superstrikes
    @superstrikes ||= convictions.flat_map(&:counts).
      select(&:superstrike?).
      map(&:code_section)
  end

  def counts
    eligible_events.flat_map(&:counts)
  end

  def eligible_events
    events_in_sf.map { |e| EventWithEligibility.new(e) }
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
