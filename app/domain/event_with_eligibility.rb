class EventWithEligibility < SimpleDelegator
  def counts
    super.map { |c| CountWithEligibility.new(c) }
  end
end

