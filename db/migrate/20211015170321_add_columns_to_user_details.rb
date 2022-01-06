class AddColumnsToUserDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :user_details, :nationality, :string
    add_column :user_details, :signature, :string
    add_column :user_details, :guarantor, :string
  end
end
