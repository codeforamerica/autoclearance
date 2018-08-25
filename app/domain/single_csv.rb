class SingleCSV
  def initialize(eligibility)
    @rows = eligibility.eligible_events.flat_map do |event|
      event.potentially_eligible_counts.map do |count|
        count_data(count, event, eligibility)
      end
    end
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

  def count_data(count, event, eligibility)
    [
      name(event, eligibility.personal_info),
      event.date,
      event.case_number,
      event.courthouse,
      count.code_section,
      count.disposition.severity,
      event.sentence,
      eligibility.superstrikes.map(&:code_section).join(', '),
      eligibility.has_three_convictions_of_same_type?(count.code_section),
      eligibility.sex_offender_registration?,
      event.remedy,
      count.csv_eligibility_column(event, eligibility),
      eligibility.has_deceased_event?
    ]
  end

  def name(event, personal_info)
    return unless personal_info

    personal_info.names[event.name_code]
  end

  def header
    [
      'Name',
      'Date',
      'Case Number',
      'Courthouse',
      'Charge',
      'Severity',
      'Sentence',
      'Superstrikes',
      '2 prior convictions',
      'PC290',
      'Remedy',
      'Eligible',
      'Deceased'
    ]
  end

  attr_reader :rows
end
