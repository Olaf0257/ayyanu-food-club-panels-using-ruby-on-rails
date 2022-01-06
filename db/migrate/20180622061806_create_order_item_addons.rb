class CreateOrderItemAddons < ActiveRecord::Migration[5.1]
  def change
    create_table :order_item_addons do |t|
    	t.references :order_item, foreign_key: true
      	t.references :item_addon, foreign_key: true
      t.timestamps
    end
  end
end
