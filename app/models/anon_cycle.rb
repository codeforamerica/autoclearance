class AnonCycle < ApplicationRecord
  belongs_to :anon_rap_sheet
  has_many :anon_events, dependent: :destroy

  def self.build_from_parser(cycle)
    events = cycle.events.map do |event|
      if (event.is_a?(RapSheetParser::CourtEvent) && event.conviction?) || event.is_a?(RapSheetParser::ArrestEvent)
        AnonEvent.build_from_parser(event)
      end
    end.compact
    
    AnonCycle.new(anon_events: events)
  end
end
