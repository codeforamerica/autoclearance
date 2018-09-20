class EventWithEligibility < SimpleDelegator
  def initialize(event:, eligibility:)
    super(event)

    @eligibility = eligibility
  end

  def counts
    super.map { |c| CountWithEligibility.new(count: c, event: self, eligibility: eligibility) }
  end

  def convicted_counts
    super.map { |c| CountWithEligibility.new(count: c, event: self, eligibility: eligibility) }
  end

  def potentially_eligible_counts
    convicted_counts.select(&:potentially_eligible?)
  end

  def eligible_counts
    convicted_counts.select do |count|
      %w[yes maybe].include?(count.eligible?)
    end
  end

  def cycle_events
    super.map { |e| self.class.new(event: e, eligibility: eligibility) }
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

  private

  attr_reader :eligibility
end
