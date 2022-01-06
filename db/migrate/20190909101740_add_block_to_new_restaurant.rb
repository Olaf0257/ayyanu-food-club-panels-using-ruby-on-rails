class AddBlockToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :block, :string
  end
end
