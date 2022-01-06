class TransferArticle < ApplicationRecord
  belongs_to :transfer_order
  belongs_to :inventory
  belongs_to :article
  belongs_to :user
  belongs_to :restaurant

  before_validation :add_details

  def add_details
    self.user = transfer_order.user
    self.restaurant = transfer_order.restaurant
    inventory = article.inventories.where(inventoryable_type: transfer_order.source_type, inventoryable_id: transfer_order.source_id).where("stock >= #{quantity}").first
    self.inventory = inventory
    self.net_amount = article.purchase_price * quantity
  end

  def transfer_article_inventory
    inventory.update(stock: inventory.stock - quantity)
    new_inventory = inventory.dup
    new_inventory.update(inventoryable_id: transfer_order.destination_id, inventoryable_type: transfer_order.destination_type, stock: quantity)
  end

end
