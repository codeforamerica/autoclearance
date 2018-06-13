class SingleCSV
  def initialize(eligibility)
    @rows = eligibility.counts.map do |count|
      count_data(count, eligibility)
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

  def count_data(count, eligibility)
    [
      count.event.date,
      count.event.case_number,
      count.event.courthouse,
      count.code_section,
      count.severity,
      count.event.sentence,
      count.prop64_eligible?
    ] + additional_eligibility_info(count, eligibility)
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
      'Needs info across state lines',
      'Superstrikes',
      '2 prior convictions',
      'PC290'
    ]
  end

  def additional_eligibility_info(count, eligibility)
    if count.prop64_eligible?
      [
        count.needs_info_under_18?,
        count.needs_info_under_21?,
        count.needs_info_across_state_lines?,
        eligibility.superstrikes.map(&:code_section).join(', '),
        eligibility.has_two_prior_convictions_of_same_type?(count),
        eligibility.pc290?
      ]
    else
      [false, false, false, "", false, false]
    end
  end

  attr_reader :rows
end
