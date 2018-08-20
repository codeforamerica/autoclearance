class AnonCycle < ApplicationRecord
  belongs_to :anon_rap_sheet
  has_many :anon_events, dependent: :destroy

  def self.build_from_parser(cycle)
    events = cycle.events.map do |event|
      if court_event?(event) || arrest_event?(event)
        AnonEvent.build_from_parser(event)
      end
    end.compact
    
    AnonCycle.new(anon_events: events)
  end

  private

  def self.arrest_event?(event)
    event.is_a?(RapSheetParser::OtherEvent) && event.header == 'arrest'
  end

  def self.court_event?(event)
    event.is_a?(RapSheetParser::CourtEvent)
  end
end
