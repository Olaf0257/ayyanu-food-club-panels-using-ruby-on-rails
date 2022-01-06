class AddNameChangeRequestedOnToRestaurants < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurants, :name_change_requested_on, :datetime
  end
end
