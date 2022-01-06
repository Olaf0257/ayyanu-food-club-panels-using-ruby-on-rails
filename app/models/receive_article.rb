class ReceiveArticle < ApplicationRecord
  belongs_to :restaurant, optional: true
  belongs_to :user, optional: true
  belongs_to :store, optional: true
  belongs_to :article
  belongs_to :receive_order, optional: true
  before_validation :calculate_net
  after_save :add_inventory

  has_one :inventory

  enum status: [:confirmed, :cancelled]

  def calculate_net
    self.user = receive_order.user
    self.restaurant = receive_order.restaurant
    self.store = receive_order.store
    self.stock = quantity
    self.discount_percentage = rate/discount if discount.present? && discount_percentage.blank? && discount > 0
    #self.discount = rate * discount_percentage if discount_percentage.present? && discount.blank?
    self.net_amount = (rate - discount) * quantity
    self.vat_percentage = article.vat.percentage
    self.vat = net_amount * article.vat.percentage/100
    self.total = vat + net_amount
  end

  def add_inventory
    inventory = store.inventories.find_or_create_by(receive_article_id: self.id)
    inventory.update(article_id: article_id, restaurant_id: restaurant_id, stock: stock, user: user) if inventory.present?
  end
end
