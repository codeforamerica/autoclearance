class SummaryCSV < SingleCSV
  def initialize
    @rows = []
  end

  def append(filename, eligibility)
    eligibility.counts.each do |count|
      rows << [filename] + count_data(count, eligibility)
    end
  end

  private
  
  def header
    ['Filename'] + super
  end
end
