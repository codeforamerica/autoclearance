class AnonCount < ApplicationRecord
  belongs_to :anon_event
  has_one :anon_disposition, dependent: :destroy

  def self.build_from_parser(count)
    AnonCount.new(
      code: count.code,
      section: count.section,
      description: count.code_section_description,
      severity: count.severity,
      anon_disposition: AnonDisposition.build_from_parser(count.disposition)
    )
  end
end
