class CreatePosTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :pos_transactions do |t|
      t.references :branch, foreign_key: true
      t.references :menu_item, foreign_key: true
      t.integer :qty, default: 0
      t.string :item_name
      t.float :item_price, default: 0.0
      t.float :total_amount, default: 0.0

      t.timestamps
    end
  end
end
