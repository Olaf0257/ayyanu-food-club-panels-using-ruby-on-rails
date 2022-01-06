class AddBusyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :busy, :boolean, default: false, null: false
  end
end
