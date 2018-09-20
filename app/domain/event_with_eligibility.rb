class EventWithEligibility < SimpleDelegator
  def counts
    super.map { |c| CountWithEligibility.new(count: c, event: self) }
  end

  def convicted_counts
    super.map { |c| CountWithEligibility.new(count: c, event: self) }
  end

  def potentially_eligible_counts
    convicted_counts.select(&:potentially_eligible?)
  end

  def eligible_counts(eligibility)
    convicted_counts.select do |count|
      %w[yes maybe].include?(count.eligible?(eligibility))
    end
  end

  def cycle_events
    super.map { |e| self.class.new(e) }
  end

  def remedy
    return 'redesignation' if sentence.nil?

    sentence_still_active = date + sentence.total_duration > Time.zone.today
    if sentence_still_active
      'resentencing'
    else
      'redesignation'
    end
  end
end
