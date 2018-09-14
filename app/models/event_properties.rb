class EventProperties < ApplicationRecord
  belongs_to :anon_event

  def self.build(event:, rap_sheet:)
    EventProperties.new(
      has_felonies: event.severity == 'F',
      has_probation: event.has_sentence_with?(:probation),
      has_prison: event.has_sentence_with?(:prison),
      has_probation_violations: event.probation_violated?(rap_sheet),
      dismissed_by_pc1203: event.dismissed_by_pc1203?
    )
  end
end
