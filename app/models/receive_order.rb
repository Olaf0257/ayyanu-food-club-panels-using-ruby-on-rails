class ReceiveOrder < ApplicationRecord
  belongs_to :restaurant
  belongs_to :user
  belongs_to :store
  belongs_to :vendor
  belongs_to :country
  belongs_to :branch
  belongs_to :purchase_order, optional: true
  
  has_many :articles, through: :receive_articles
  has_many :receive_articles, inverse_of: :receive_order, dependent: :destroy
  accepts_nested_attributes_for :receive_articles, reject_if: :all_blank, allow_destroy: true
  after_commit :update_purchase_order_status, if: :purchase_order
  after_commit :update_receive_article_status, if: Proc.new{ status.eql?('cancelled') }

  enum status: [:confirmed, :cancelled]

  def update_purchase_order_status
    purchase_order.update(status: 'received')
  end

  def update_receive_article_status
    receive_articles.update_all(status: 'cancelled', stock: 0)
  end

  def self.search(condition)
    key = "%#{condition}%"
    where("restaurant_id LIKE :condition", condition: key)
  end

end
