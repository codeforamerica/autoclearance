class AnonCycle < ApplicationRecord
  belongs_to :anon_rap_sheet
  has_many :anon_events, dependent: :destroy

  def self.create_from_parser(cycle, anon_rap_sheet:)
    anon_cycle = AnonCycle.create!(anon_rap_sheet: anon_rap_sheet)

    cycle.events.each do |event|
      if event.is_a?(RapSheetParser::CourtEvent) && event.conviction?
        AnonEvent.create_from_parser(event, anon_cycle: anon_cycle)
      end
    end
    anon_cycle
  end
end
