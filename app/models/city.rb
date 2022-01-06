class City < ApplicationRecord
  has_many :coverage_areas, dependent: :destroy
end
