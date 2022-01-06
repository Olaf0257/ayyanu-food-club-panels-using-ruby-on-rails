class AddUserIdToEnterprises < ActiveRecord::Migration[5.2]
  def change
    add_column :enterprises, :user_id, :integer
  end
end
