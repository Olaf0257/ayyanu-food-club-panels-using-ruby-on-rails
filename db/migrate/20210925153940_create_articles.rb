class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :name
      t.string :article_type
      t.string :price_type
      t.float :purchase_price
      t.float :planned_price
      t.float :last_purchase_price
      t.string :calorie
      t.string :base_unit
      t.string :store_unit
      t.string :expires_in
      t.float :weight
      t.references :over_group, foreign_key: true
      t.references :major_group, foreign_key: true
      t.references :item_group, foreign_key: true

      t.timestamps
    end
  end
end
