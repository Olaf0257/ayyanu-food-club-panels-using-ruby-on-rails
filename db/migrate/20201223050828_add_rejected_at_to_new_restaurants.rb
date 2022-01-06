class AddRejectedAtToNewRestaurants < ActiveRecord::Migration[5.2]
  def change
    add_column :new_restaurants, :rejected_at, :datetime
  end
end
