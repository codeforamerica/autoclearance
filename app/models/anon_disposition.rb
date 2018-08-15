class AnonDisposition < ApplicationRecord
  belongs_to :anon_count

  def self.create_from_parser(disposition, anon_count:)
    AnonDisposition.create!(
      disposition_type: disposition.type,
      sentence: disposition.sentence,
      anon_count: anon_count
    )
  end
end
