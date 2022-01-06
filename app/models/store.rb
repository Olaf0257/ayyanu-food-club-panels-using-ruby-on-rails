class Store < ApplicationRecord
  serialize :store_category, Array
  serialize :country_ids, Array
  serialize :branch_ids, Array
  belongs_to :restaurant
  belongs_to :tax
  belongs_to :user
  belongs_to :store_type
  belongs_to :city, optional: true
  belongs_to :area, class_name: "CoverageArea"
  has_many :inventories, as: :inventoryable

  STORE_CATEGORIES = ["Store", "Cost Center", "Expense on Store", "Permanent Inventory"]

  def full_address
    [address, block, road_no, building, floor].join(', ')
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

  def self.search(condition)
    where("name like ?", "#{condition}%")
  end
end
