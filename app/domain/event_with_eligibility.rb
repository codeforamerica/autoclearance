class EventWithEligibility < SimpleDelegator
  def counts
    super.map { |c| CountWithEligibility.new(c) }
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

