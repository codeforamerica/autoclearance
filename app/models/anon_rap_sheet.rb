class AnonRapSheet < ApplicationRecord
  validates_presence_of :county, :checksum
end
