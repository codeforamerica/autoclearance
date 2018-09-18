class AnonEvent < ApplicationRecord
  belongs_to :anon_cycle
  has_many :anon_counts, dependent: :destroy
  has_one :event_properties, dependent: :destroy

  VALID_EVENT_TYPES = ['court', 'arrest', 'applicant', 'probation', 'custody', 'registration', 'supplemental_arrest', 'deceased', 'mental_health']

  validates :event_type, presence: true
  validates :event_type, inclusion: { in: VALID_EVENT_TYPES }

  default_scope { order(date: :asc) }

  def self.build_from_parser(event:, rap_sheet:)
    counts = event.counts.map.with_index(1) do |count, i|
      AnonCount.build_from_parser(
        index: i,
        count: count,
        event: event,
        rap_sheet: rap_sheet
      )
    end

    AnonEvent.new(
      agency: event.agency,
      event_type: event.header,
      date: event.date,
      anon_counts: counts,
      event_properties: event_properties(event: event, rap_sheet: rap_sheet)
    )
  end

  def self.event_properties(event:, rap_sheet:)
    return unless event.is_a?(RapSheetParser::CourtEvent) && event.conviction?

    EventProperties.build(event: event, rap_sheet: rap_sheet)
  end
end
