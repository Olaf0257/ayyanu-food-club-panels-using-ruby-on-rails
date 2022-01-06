class AddIsSignedToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :is_signed, :boolean,default: true
  end
end
