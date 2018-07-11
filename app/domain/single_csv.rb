class SingleCSV
  def initialize(eligibility)
    @rows = eligibility.eligible_events.flat_map do |event|
      event.counts.map do |count|
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
      eligibility.personal_info.names[event.name_code],
      event.date,
      event.case_number,
      event.courthouse,
      count.code_section,
      count.severity,
      event.sentence,
      count.prop64_conviction?
    ] + additional_eligibility_info(count, event, eligibility)
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
      'Prop 64 Conviction',
      'Superstrikes',
      '2 prior convictions',
      'PC290',
      'Remedy',
      'Eligible'
    ]
  end

  def additional_eligibility_info(count, event, eligibility)
    if count.prop64_conviction?
      [
        eligibility.superstrikes.map(&:code_section).join(', '),
        eligibility.has_two_prior_convictions_of_same_type?(event, count),
        eligibility.sex_offender_registration?,
        event.remedy,
        eligibility.prop64_eligible(event, count)
      ]
    else
      ["", false, false, "", false]
    end
  end


  attr_reader :rows
end
