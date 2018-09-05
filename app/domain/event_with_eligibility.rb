class EventWithEligibility < SimpleDelegator
  def counts
    super.map { |c| CountWithEligibility.new(c) }
  end

  def convicted_counts
    super.map { |c| CountWithEligibility.new(c) }
  end

  def potentially_eligible_counts
    convicted_counts.select { |count| count.potentially_eligible?(self) }
  end

  def eligible_counts(eligibility)
    convicted_counts.select { |count| count.eligible?(self, eligibility) }
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
