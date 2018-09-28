class SummaryCSV
  def initialize
    @rows = []
  end

  def append(filename, prop64_classifiers)
    prop64_classifiers
      .select(&:potentially_eligible?)
      .each do |classifier|
      rows << [filename] + classifier_data(classifier)
    end
  end

  def text
    CSV.generate do |csv|
      csv << header
      rows.each { |row| csv << row }
    end
  end

  private

  def header
    [
      'Filename',
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

  def classifier_data(classifier)
    event = classifier.event
    rap_sheet = classifier.rap_sheet

    [
      name(event, rap_sheet.personal_info),
      event.date,
      event.case_number,
      event.courthouse,
      classifier.code_section,
      classifier.disposition.severity,
      event.sentence,
      rap_sheet.superstrikes.map(&:code_section).join(', '),
      classifier.has_three_convictions_of_same_type?,
      rap_sheet.sex_offender_registration?,
      classifier.remedy,
      classifier.eligible?,
      rap_sheet.deceased_events.any?
    ]
  end

  def name(event, personal_info)
    return unless personal_info

    personal_info.names[event.name_code]
  end

  attr_reader :rows
end
