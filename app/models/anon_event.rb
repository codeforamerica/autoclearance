class AnonEvent < ApplicationRecord
  belongs_to :anon_rap_sheet
  has_many :anon_counts, dependent: :destroy

  validates_presence_of :event_type
  validates_inclusion_of :event_type, in: ['court']

  def self.create_from_parser(event, anon_rap_sheet:)
    anon_event = AnonEvent.create!(
      agency: event.courthouse,
      event_type: 'court',
      date: event.date,
      anon_rap_sheet: anon_rap_sheet
    )

    event.counts.map do |count|
      AnonCount.create_from_parser(count, anon_event: anon_event)
    end

    anon_event
  end
end
