class OverGroup < ApplicationRecord
  serialize :branch_ids, Array
  serialize :country_ids, Array
  belongs_to :restaurant
  belongs_to :user

  def self.search(condition)
    key = "%#{condition}%"
    where("name LIKE :condition OR operation_type LIKE :condition", condition: key)
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
