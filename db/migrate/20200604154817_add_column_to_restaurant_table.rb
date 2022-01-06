class AddColumnToRestaurantTable < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :country_id, :integer
  end
end
