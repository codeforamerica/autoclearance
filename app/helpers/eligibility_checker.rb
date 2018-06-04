class EligibilityChecker
  def initialize(events)
    @events = events
  end

  def eligible_events
    events.select do |e|
      if e.courthouse.include? 'SAN FRANCISCO'
        Rails.logger.tagged('UNEXPECTED INPUT') { Rails.logger.warn("Unknown Courthouse: #{e.courthouse}") }
      end

      e.courthouse.upcase.include? 'SAN FRANCISCO'
    end
  end

  private

  attr_reader :events
end
