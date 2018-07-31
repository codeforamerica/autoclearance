class RapSheetWithEligibility < SimpleDelegator
  def initialize(rap_sheet, logger:)
    super(rap_sheet)

    unless potentially_eligible_counts?
      logger.warn('No eligible prop64 convictions found')
    end
  end

  def eligible_events
    convictions.
      select { |e| in_sf?(e) }.
      reject(&:dismissed_by_pc1203?).
      map { |e| EventWithEligibility.new(e) }
  end

  def potentially_eligible_counts?
    eligible_events.any? do |eligible_event|
      eligible_event.potentially_eligible_counts.any?
    end
  end

  def disqualifiers?(code_section)
    sex_offender_registration? ||
      superstrikes.any? ||
      has_three_convictions_of_same_type?(code_section)
  end

  def has_three_convictions_of_same_type?(code_section)
    convictions.select do |e|
      e.convicted_counts.any? do |c|
        c.code_section_starts_with([code_section])
      end
    end.length >= 3
  end
  
  private

  def in_sf?(e)
    sf_county_courthouses = ['CASC San Francisco', 'CASC San Francisco Co', 'CAMC San Francisco']
    sf_county_courthouses.include? e.courthouse
  end
end
