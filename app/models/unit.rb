class Unit < ApplicationRecord
  serialize :branch_ids, Array
  serialize :country_ids, Array
  belongs_to :restaurant
  belongs_to :user

  BASE_UNIT = ['Each', 'Hour', 'Kilogram', 'Kilowatt', 'Liter', 'Meter', 'Portion', 'Square Meter', 'Volume Unit']

  def self.search(condition)
    where("name like ?", "#{condition}%")
  end

  def branches
    Branch.where(id: self.branch_ids)
  end

  def addresses
    branches.pluck(:address).join(', ')
  end

  def countries
    Country.where(id: self.country_ids)
  end

  def country_names
    countries.pluck(:name).join(', ')
  end
end
