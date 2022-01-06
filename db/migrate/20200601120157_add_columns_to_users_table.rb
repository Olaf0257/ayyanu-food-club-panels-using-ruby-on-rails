class AddColumnsToUsersTable < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :is_approved, :tinyint, :limit => 2, :default => 0
    add_column :users, :is_rejected, :tinyint, :limit => 2, :default => 0
    add_column :users, :reject_reason, :string
  end
end
