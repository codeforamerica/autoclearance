class Eligibility
  def initialize(convictions)
    @convictions = convictions
  end

  def superstrikes
    @superstrikes ||= convictions.flat_map(&:counts).
      select(&:superstrike?).
      map(&:code_section)
  end

  def counts
    eligible_convictions = EligibilityChecker.new(convictions).eligible_events
    eligible_convictions.flat_map(&:counts)
  end

  private

  attr_reader :convictions
end
