class AddCreatedByToUserDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :user_details, :created_by_id, :integer
    add_column :user_details, :pan_number, :integer
  end
end
