class PurchaseArticle < ApplicationRecord
  belongs_to :purchase_order, optional: true
  belongs_to :article, optional: true
  belongs_to :user, optional: true
  belongs_to :restaurant, optional: true
  before_validation :calculate_net

  def calculate_net
    self.net_amount = article.purchase_price * quantity
    self.user = purchase_order.user
    self.restaurant = purchase_order.restaurant
  end

end
