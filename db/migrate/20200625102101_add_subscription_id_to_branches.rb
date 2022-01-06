class AddSubscriptionIdToBranches < ActiveRecord::Migration[5.2]
  def change
    add_reference :branches, :report_subscription
    add_reference :branches, :branch_subscription
  end
end
