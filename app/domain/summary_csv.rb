class SummaryCSV < SingleCSV
  def initialize
    @rows = []
  end

  def append(filename, eligibility)
    eligibility.eligible_events.each do |event|
      event.counts.each do |count|
        rows << [filename] + count_data(count, event, eligibility)
      end
    end
  end

  private
  
  def header
    ['Filename'] + super
  end
end
