class AddReportExpairedAtToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :report_expaired_at, :date
  end
end
