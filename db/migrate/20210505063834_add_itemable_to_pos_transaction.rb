class AddItemableToPosTransaction < ActiveRecord::Migration[5.2]
  def change
  	add_reference :pos_transactions, :itemable, polymorphic: true, index: true
  	remove_reference :pos_transactions, :menu_item, index: true, foreign_key: true
  end
end
