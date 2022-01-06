class CreateCartItems < ActiveRecord::Migration[5.1]
  def change
    create_table :cart_items do |t|
      t.references :menu_item, foreign_key: true
      t.references :cart, foreign_key: true
      t.string :quantity
      t.string :description

      t.timestamps
    end
  end
end
