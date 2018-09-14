class AnonCycle < ApplicationRecord
  belongs_to :anon_rap_sheet
  has_many :anon_events, dependent: :destroy

  def self.build_from_parser(cycle:, rap_sheet:)
    events = cycle.events.map do |event|
      AnonEvent.build_from_parser(event: event, rap_sheet: rap_sheet)
    end

    AnonCycle.new(anon_events: events)
  end
end
