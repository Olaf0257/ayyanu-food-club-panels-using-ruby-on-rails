class AddUserIdToUserDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :user_details, :user_id, :integer
  end
end
