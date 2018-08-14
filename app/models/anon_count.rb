class AnonCount < ApplicationRecord
  belongs_to :anon_event

  def self.create_from_parser(count, anon_event:)
    AnonCount.create!(
      code: count.code,
      section: count.section,
      description: count.code_section_description,
      severity: count.severity,
      anon_event: anon_event
    )
  end
end
