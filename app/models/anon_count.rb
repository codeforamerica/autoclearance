class AnonCount < ApplicationRecord
  belongs_to :anon_event
  has_one :anon_disposition, dependent: :destroy

  def self.create_from_parser(count, anon_event:)
    anon_count = AnonCount.create!(
      code: count.code,
      section: count.section,
      description: count.code_section_description,
      severity: count.severity,
      anon_event: anon_event
    )

    AnonDisposition.create_from_parser(count.disposition, anon_count: anon_count)
  end
end
