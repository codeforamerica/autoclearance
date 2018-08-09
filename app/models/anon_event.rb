class AnonEvent < ApplicationRecord
  belongs_to :anon_rap_sheet
  validates_presence_of :event_type 
  
  def self.build_from_parser(event)
    AnonEvent.new(
      agency: event.courthouse,
      event_type: 'court',
      date: event.date
    )
  end
end
