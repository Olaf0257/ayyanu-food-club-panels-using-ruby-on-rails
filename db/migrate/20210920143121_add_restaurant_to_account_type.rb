class AddRestaurantToAccountType < ActiveRecord::Migration[5.2]
  def change
    add_reference :account_types, :restaurant, foreign_key: true
  end
end
