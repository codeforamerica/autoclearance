class AnonEvent < ApplicationRecord
  belongs_to :anon_cycle
  has_many :anon_counts, dependent: :destroy

  VALID_EVENT_TYPES = ['court', 'arrest', 'applicant', 'probation', 'custody', 'registration', 'supplemental_arrest', 'deceased', 'mental_health']

  validates_presence_of :event_type
  validates_inclusion_of :event_type, in: VALID_EVENT_TYPES

  default_scope { order(date: :asc) }

  def self.build_from_parser(event)
    counts = event.counts.map.with_index(1) do |count, i|
      AnonCount.build_from_parser(count, i)
    end

    AnonEvent.new(
      agency: event.agency,
      event_type: event.header,
      date: event.date,
      anon_counts: counts
    )
  end
end
