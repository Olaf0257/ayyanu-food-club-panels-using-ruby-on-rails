class AddRatingToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :rating, :float,default: 4.0
  end
end
