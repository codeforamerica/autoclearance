class RapSheetWithEligibility < SimpleDelegator
  attr_reader :county

  def initialize(rap_sheet:, county:, logger:)
    super(rap_sheet)
    @county = county

    unless potentially_eligible_counts?
      logger.warn('No eligible prop64 convictions found')
    end
  end

  def eligible_events
    convictions
      .select { |e| in_courthouses?(e) }
      .reject(&:dismissed_by_pc1203?)
      .map { |e| EventWithEligibility.new(event: e, eligibility: self) }
  end

  def potentially_eligible_counts?
    eligible_events.any? do |eligible_event|
      eligible_event.potentially_eligible_counts.any?
    end
  end

  def disqualifiers?
    sex_offender_registration? || superstrikes.any?
  end

  def has_three_convictions_of_same_type?(code_section)
    convictions.select do |e|
      e.convicted_counts.any? do |c|
        c.subsection_of?([code_section])
      end
    end.length >= 3
  end

  def has_deceased_event?
    return @has_deceased_events unless @has_deceased_events.nil?
    @has_deceased_events = deceased_events.any?
  end

  private

  def in_courthouses?(e)
    county[:courthouses].include? e.courthouse
  end
end
