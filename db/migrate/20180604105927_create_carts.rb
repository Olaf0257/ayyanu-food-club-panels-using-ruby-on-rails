class CreateCarts < ActiveRecord::Migration[5.1]
  def change
    create_table :carts do |t|
      t.references :user, foreign_key: true
      t.references :branch, foreign_key: true
      t.string :description

      t.timestamps
    end
  end
end
