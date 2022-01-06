class RenameRestaurantColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :restaurants, :is_approved, :approved
    rename_column :restaurants, :is_rejected, :rejected
  end
end
