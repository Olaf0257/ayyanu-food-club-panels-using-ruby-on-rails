class AddGoogleAuthColumnsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :google_token, :string
    add_column :users, :google_refresh_token, :string
  end
end
