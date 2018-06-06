class SingleCSV
  def initialize(counts)
    @rows = counts.map { |count| count_data(count) }
  end

  def text
    CSV.generate do |csv|
      csv << header
      rows.each do |row|
        csv << row
      end
    end
  end

  private
    
    def count_data(count)
      [
        count.event.date,
        count.event.case_number,
        count.event.courthouse,
        count.code_section,
        count.severity,
        count.event.sentence,
        count.prop64_eligible?,
        count.needs_info_under_18?,
        count.needs_info_under_21?,
        count.needs_info_across_state_lines?
      ]
    end

  def header
    [
      'Date',
      'Case Number',
      'Courthouse',
      'Charge',
      'Severity',
      'Sentence',
      'Prop 64 Eligible',
      'Needs info under 18',
      'Needs info under 21',
      'Needs info across state lines'
    ]
  end

  attr_reader :rows
end
