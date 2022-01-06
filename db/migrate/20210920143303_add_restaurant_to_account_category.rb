class AddRestaurantToAccountCategory < ActiveRecord::Migration[5.2]
  def change
    add_reference :account_categories, :restaurant, foreign_key: true
  end
end
