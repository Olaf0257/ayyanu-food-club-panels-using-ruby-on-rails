class AddHsIdToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :hs_id, :integer
  end
end
