class AddUserIdToSuggestRestaurants < ActiveRecord::Migration[5.2]
  def change
    add_reference :suggest_restaurants, :user, foreign_key: true, index: true
  end
end
