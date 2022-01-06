class CreateSuggestRestaurants < ActiveRecord::Migration[5.1]
  def change
    create_table :suggest_restaurants do |t|
      t.string :description
      t.references :restaurant, foreign_key: true
      t.references :coverage_area, foreign_key: true
      t.timestamps
    end
  end
end
