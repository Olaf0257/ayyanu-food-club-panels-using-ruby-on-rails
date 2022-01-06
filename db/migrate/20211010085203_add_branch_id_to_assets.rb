class AddBranchIdToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :branch_id, :integer
  end
end
