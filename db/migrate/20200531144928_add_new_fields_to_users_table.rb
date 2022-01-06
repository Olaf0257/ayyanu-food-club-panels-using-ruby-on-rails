class AddNewFieldsToUsersTable < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :country_id, :integer, after: :country_code
    add_column :users, :role_id, :integer, after: :country_id
  end
end
