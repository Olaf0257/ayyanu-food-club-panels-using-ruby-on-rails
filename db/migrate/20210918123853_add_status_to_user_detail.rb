class AddStatusToUserDetail < ActiveRecord::Migration[5.2]
  def change
    add_column :user_details, :status, :string
  end
end
