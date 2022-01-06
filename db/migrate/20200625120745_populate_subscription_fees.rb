class PopulateSubscriptionFees < ActiveRecord::Migration[5.2]
  def up
    BranchSubscription.create(fee: 0, country_id: 15)
    ReportSubscription.create(fee: 0, country_id: 15)
    Branch.where(is_approved: true).update_all(branch_subscription_id: 1, report_subscription_id: 1)
  end
end
