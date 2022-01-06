class AddDeliveryStatusToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :delivery_status, :string
    add_column :new_restaurants, :branch_no, :integer
  end
end
