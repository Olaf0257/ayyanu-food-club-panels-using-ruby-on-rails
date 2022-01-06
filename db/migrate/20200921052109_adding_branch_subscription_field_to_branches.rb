class AddingBranchSubscriptionFieldToBranches < ActiveRecord::Migration[5.2]
  def change
    add_column :branches, :report, :boolean, null: false, default: true
  end
end
