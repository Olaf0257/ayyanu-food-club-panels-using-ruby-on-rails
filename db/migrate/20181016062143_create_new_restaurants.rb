class CreateNewRestaurants < ActiveRecord::Migration[5.1]
  def change
    create_table :new_restaurants do |t|
      t.string :restaurant_name
      t.string :person_name
      t.string :contact_number
      t.string :role
      t.string :email
      t.references :coverage_area, foreign_key: true
      t.string :cuisine

      t.timestamps
    end
  end
end
