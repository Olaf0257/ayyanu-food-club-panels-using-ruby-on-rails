class AddTypeToNewRestaurantImage < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurant_images, :type, :string
  end
end
