class AddIsApprovedToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :is_approved,:boolean,default: false
  end
end
