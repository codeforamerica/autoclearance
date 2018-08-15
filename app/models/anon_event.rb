class AnonEvent < ApplicationRecord
  belongs_to :anon_cycle
  has_many :anon_counts, dependent: :destroy

  validates_presence_of :event_type
  validates_inclusion_of :event_type, in: ['court', 'arrest']

  default_scope { order(date: :asc) }

  def self.build_from_parser(event)
    counts = event.counts.map.with_index(1) do |count, i|
      AnonCount.build_from_parser(count, i)
    end

    AnonEvent.new(
      agency: event.agency,
      event_type: event_type(event),
      date: event.date,
      anon_counts: counts
    )
  end

  private

  def self.event_type(event)
    if event.is_a? RapSheetParser::CourtEvent
      'court'
    elsif event.is_a? RapSheetParser::OtherEvent
      event.header
    end
  end
end
