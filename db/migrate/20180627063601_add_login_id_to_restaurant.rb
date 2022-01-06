class AddLoginIdToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :login_id, :string
  end
end
