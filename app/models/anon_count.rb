class AnonCount < ApplicationRecord
  belongs_to :anon_event

  def self.create_from_parser(count)
    AnonCount.new(
      code: count.code,
      section: count.section,
      description: count.code_section_description,
      severity: count.severity
    )
  end
end
