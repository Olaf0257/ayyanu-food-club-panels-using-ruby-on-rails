class MajorGroup < ApplicationRecord
  serialize :branch_ids, Array
  serialize :country_ids, Array
  belongs_to :restaurant
  belongs_to :over_group
  belongs_to :user

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
