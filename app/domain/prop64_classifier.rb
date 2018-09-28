class Prop64Classifier < SimpleDelegator
  attr_reader :event, :rap_sheet

  def initialize(count:, event:, rap_sheet:, county:)
    super(count)
    @event = event
    @rap_sheet = rap_sheet
    @county = county
  end

  def potentially_eligible?
    return false if county_filtered

    prop64_conviction? || plea_bargain_classifier.possible_plea_bargain?
  end

  def prop64_conviction?
    subsection_of?(CodeSections::PROP64_DISMISSIBLE) && !subsection_of?(CodeSections::PROP64_INELIGIBLE)
  end

  def eligible?
    return 'no' unless potentially_eligible? && !disqualifiers? && !has_two_prop_64_priors?
    return 'yes' if plea_bargain_classifier.plea_bargain?
    return 'maybe' if plea_bargain_classifier.possible_plea_bargain?
    'yes'
  end

  def has_two_prop_64_priors?
    two_priors_codes = ['HS 11358', 'HS 11359', 'HS 11360']
    two_priors_codes.include?(code_section) && has_three_convictions_of_same_type?
  end

  def plea_bargain
    return 'yes' if plea_bargain_classifier.plea_bargain?
    return 'maybe' if plea_bargain_classifier.possible_plea_bargain?
    'no'
  end

  def has_three_convictions_of_same_type?
    rap_sheet.convictions.select do |e|
      e.convicted_counts.any? do |c|
        c.subsection_of?([code_section])
      end
    end.length >= 3
  end

  def remedy
    return 'redesignation' if event.sentence.nil?

    sentence_still_active = event.date + event.sentence.total_duration > Time.zone.today
    if sentence_still_active
      'resentencing'
    else
      'redesignation'
    end
  end

  private

  attr_reader :county

  def county_filtered
    county[:misdemeanors] == false && disposition.severity == 'M'
  end

  def plea_bargain_classifier
    PleaBargainClassifier.new(self)
  end

  def disqualifiers?
    rap_sheet.sex_offender_registration? || rap_sheet.superstrikes.any?
  end
end
