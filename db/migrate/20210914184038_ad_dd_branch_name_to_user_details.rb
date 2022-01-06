class AdDdBranchNameToUserDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :user_details, :dd_branch_name, :string
  end
end
