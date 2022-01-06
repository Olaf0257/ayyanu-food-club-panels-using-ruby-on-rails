class CreateNewRestaurantImages < ActiveRecord::Migration[5.1]
  def change
    create_table :new_restaurant_images do |t|
      t.string :url
      t.references :new_restaurant, foreign_key: true

      t.timestamps
    end
  end
end
