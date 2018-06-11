class Eligibility
  def initialize(convictions)
    @convictions = convictions
  end
  
  def contains_superstrike?
    @contains_superstrike ||= convictions.flat_map(&:counts).any?(&:superstrike?)
  end
  
  def counts
    eligible_convictions = EligibilityChecker.new(convictions).eligible_events
    eligible_convictions.flat_map(&:counts)
  end
  
  private
  
  attr_reader :convictions
end
