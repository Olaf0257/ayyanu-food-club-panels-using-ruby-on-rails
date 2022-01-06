class AddRejectedColumnsToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :is_approved, :boolean, null: false, default: true
    add_column :restaurants, :is_rejected, :boolean, null: false, default: false
  end
end
