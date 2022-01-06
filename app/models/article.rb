class Article < ApplicationRecord
  serialize :taxes, Array
  belongs_to :over_group
  belongs_to :major_group
  belongs_to :item_group
  belongs_to :restaurant
  belongs_to :user
  has_many :ingredients, as: :ingredientable
  has_many :inventories

  has_many :ingredients, inverse_of: :article, dependent: :destroy
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank

  ARTICLE_TYPE = ["Profit Contribution", "Expenses"]
  PRICE_TYPE = ["Dynamic Price", "Fixed Price"]

  def self.search(condition)
     where("name like ?", "#{condition}%")
  end

  def all_taxes
    Tax.where(id: taxes).map(&:name_with_percentage).join(', ')
  end

  def vat
    Tax.where(id: taxes).first
  end

  def base_unit_name
    Unit.find_by(id: base_unit)&.name
  end

  def purchase_details
    name + " ( Price - #{purchase_price.to_s}, Unit - #{base_unit_name}, Stock - 0 )"
  end
end
