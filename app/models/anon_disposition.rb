class AnonDisposition < ApplicationRecord
  belongs_to :anon_count

  def self.build_from_parser(disposition)
    AnonDisposition.new(
      disposition_type: disposition.type,
      sentence: disposition.sentence,
      text: disposition.text,
      severity: disposition.severity
    )
  end
end
