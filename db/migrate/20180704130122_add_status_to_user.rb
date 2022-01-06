class AddStatusToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :status, :boolean ,default: true
  end
end
