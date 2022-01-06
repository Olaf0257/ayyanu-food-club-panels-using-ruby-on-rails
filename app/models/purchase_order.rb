class PurchaseOrder < ApplicationRecord
  belongs_to :restaurant
  belongs_to :user
  belongs_to :store
  belongs_to :vendor
  belongs_to :country
  belongs_to :branch
  
  has_one :receive_order
  has_many :inventories, as: :inventoryable
  has_many :articles, through: :purchase_articles
  has_many :purchase_articles, inverse_of: :purchase_order
  accepts_nested_attributes_for :purchase_articles, reject_if: :all_blank, allow_destroy: true

  enum status: [:pending, :booked, :rejected, :received]
  
  def self.search(condition)
    key = "%#{condition}%"
    where("restaurant_id LIKE :condition", condition: key)
  end

  def articles_list_csv
    CSV.generate do |csv|
      header = "PURCHASE ORDER"
      csv << [header]

      second_row = ["Vendor", "Delivery Date", "Total Articles No."]
      csv << second_row
      csv << [self.vendor.company_name, self.delivery_date.strftime("%d-%m-%Y %I:%M %p"), self.purchase_articles.count]

      third_row = ["Article", "Unit", "Item Quantity", "Created At"]
      csv << third_row

      purchase_articles.each do |pa|
        @row = []
        @row << pa.article.name
        @row << pa.article.base_unit_name
        @row << pa.quantity
        @row << pa.created_at.strftime("%d-%m-%Y %I:%M %p")
        csv << @row
      end
    end
  end

end
