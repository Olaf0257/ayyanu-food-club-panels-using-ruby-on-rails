class TransferOrder < ApplicationRecord
  belongs_to :country
  belongs_to :branch
  belongs_to :user
  belongs_to :restaurant

  has_many :articles, through: :transfer_articles
  has_many :transfer_articles, inverse_of: :transfer_order, dependent: :destroy
  accepts_nested_attributes_for :transfer_articles, reject_if: :all_blank, allow_destroy: true
  
  enum status: [:pending, :cancelled, :approved, :transfered]

  TYPE = ["Store", "Station"]

  def self.search(condition)
    key = "%#{condition}%"
    where("restaurant_id LIKE :condition", condition: key)
  end

  def source
    source_type.constantize.find_by(id: source_id).try(:name)
  end

  def destination
    destination_type.constantize.find_by(id: destination_id).try(:name)
  end

  def transfer_inventories
    ActiveRecord::Base.transaction do
      transfer_articles.each do |article|
        article.transfer_article_inventory
      end
      update(status: 'transfered')
    end
  end
end
