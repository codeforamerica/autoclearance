class AnonCount < ApplicationRecord
  belongs_to :anon_event
  has_one :anon_disposition, dependent: :destroy
  has_one :count_properties, dependent: :destroy
  default_scope { order(count_number: :asc) }

  def self.build_from_parser(index:, count:, event:, rap_sheet:)
    AnonCount.new(
      count_number: index,
      code: count.code,
      section: count.section,
      description: count.code_section_description,
      anon_disposition: anon_disposition(count.disposition),
      count_properties: count_properties(
        count: count,
        rap_sheet: rap_sheet,
        event: event
      )
    )
  end

  private

  def self.anon_disposition(disposition)
    return unless disposition

    AnonDisposition.build_from_parser(disposition)
  end

  def self.count_properties(count:, event:, rap_sheet:)
    return unless count.disposition&.type == 'convicted'
    CountProperties.build(
      count: count,
      rap_sheet: rap_sheet,
      event: event
    )
  end
end
