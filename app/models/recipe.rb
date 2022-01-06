class Recipe < ApplicationRecord
  belongs_to :restaurant
  belongs_to :country
  belongs_to :branch
  belongs_to :over_group
  belongs_to :major_group
  belongs_to :recipe_group
  belongs_to :unit
  belongs_to :user
  has_many :ingredients, as: :ingredientable
  serialize :station_ids, Array

  has_many :ingredients, inverse_of: :recipe, dependent: :destroy
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank
  

  def self.search(condition)
    key = "%#{condition}%"
    where("name LIKE :condition", condition: key)
  end

  def stations
    Station.where(id: self.station_ids)
  end
end
