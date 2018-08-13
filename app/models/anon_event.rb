class AnonEvent < ApplicationRecord
  belongs_to :anon_rap_sheet
  has_many :anon_counts

  validates_presence_of :event_type
  validates_inclusion_of :event_type, in: ['court']

  def self.create_from_parser(event)
    counts = event.counts.map do |count|
      AnonCount.create_from_parser(count)
    end

    AnonEvent.new(
      agency: event.courthouse,
      event_type: 'court',
      date: event.date,
      anon_counts: counts
    )
  end
end
