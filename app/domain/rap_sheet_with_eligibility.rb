class RapSheetWithEligibility < SimpleDelegator
  attr_reader :county

  def initialize(rap_sheet:, county:, logger:)
    super(rap_sheet)
    @county = county
  end

  def eligible_events
    convictions
      .select { |e| in_courthouses?(e) }
      .reject(&:dismissed_by_pc1203?)
  end

  private

  def in_courthouses?(e)
    county[:courthouses].include? e.courthouse
  end
end
