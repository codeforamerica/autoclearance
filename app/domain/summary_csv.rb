class SummaryCSV < SingleCSV
  def initialize
    @rows = []
  end

  def append(filename, counts)
    counts.each do |count|
      rows << [filename] + count_data(count)
    end
  end

  private
  
  def header
    ['Filename'] + super
  end
end
