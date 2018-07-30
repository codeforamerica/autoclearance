class EventWithEligibility < SimpleDelegator
  def counts
    super.map { |c| CountWithEligibility.new(c) }
  end

  def potentially_eligible_counts
    counts.select { |count| count.potentially_eligible?(self) }
  end

  def cycle_events
    super.map { |e| self.class.new(e) }
  end

  def remedy
    return 'redesignation' if sentence.nil?

    sentence_still_active = date + sentence.total_duration > Date.today
    if sentence_still_active
      'resentencing'
    else
      'redesignation'
    end
  end
end

