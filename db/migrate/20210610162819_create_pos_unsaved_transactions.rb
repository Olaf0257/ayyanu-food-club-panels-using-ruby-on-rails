class CreatePosUnsavedTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :pos_unsaved_transactions do |t|
      t.references :branch
      t.float :qty
      t.references :itemable, polymorphic: true, index: true
      t.string :item_name
      t.float :item_price
      t.float :total_amount
      t.text :comments
      t.integer :parent_pos_unsaved_transaction_id
      t.integer :seat_no
      t.integer :pos_check_id
      t.integer :transaction_status
      t.references :pos_transaction, foreign_key: true
      t.references :pos_table, foreign_key: true

      t.timestamps
    end
  end
end
