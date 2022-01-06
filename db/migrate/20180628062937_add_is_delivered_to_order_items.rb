class AddIsDeliveredToOrderItems < ActiveRecord::Migration[5.1]
  def change
    add_column :order_items, :is_delivered, :boolean,default: false
  end
end
