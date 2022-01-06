class AddIsApprovedToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :is_approved, :boolean,default: false
    add_column :new_restaurants, :is_rejected, :boolean,default: false
    add_column :new_restaurants, :reject_reason, :string
  end
end
