class AddIsSubscribeToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :is_subscribe, :boolean,default: false
  end
end
