class AddBranchSubscriptionFeeToServicefee < ActiveRecord::Migration[5.1]
  def change
    add_column :servicefees, :branch_subscription_fee, :float
  end
end
