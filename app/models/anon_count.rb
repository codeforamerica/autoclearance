class AnonCount < ApplicationRecord
  belongs_to :anon_event
  has_one :anon_disposition, dependent: :destroy

  def self.build_from_parser(count, index)
    AnonCount.new(
      count_number: index,
      code: count.code,
      section: count.section,
      description: count.code_section_description,
      severity: count.severity,
      anon_disposition: anon_disposition(count.disposition)
    )
  end

  private

  def self.anon_disposition(disposition)
    return unless disposition

    AnonDisposition.build_from_parser(disposition)
  end
end
