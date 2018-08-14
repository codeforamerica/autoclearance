class AnonEvent < ApplicationRecord
  belongs_to :anon_cycle
  has_many :anon_counts, dependent: :destroy

  validates_presence_of :event_type
  validates_inclusion_of :event_type, in: ['court']

  default_scope { order(date: :asc) }

  def self.create_from_parser(event, anon_cycle:)
    anon_event = AnonEvent.create!(
      agency: event.courthouse,
      event_type: 'court',
      date: event.date,
      anon_cycle: anon_cycle
    )

    event.counts.map do |count|
      AnonCount.create_from_parser(count, anon_event: anon_event)
    end

    anon_event
  end
end
