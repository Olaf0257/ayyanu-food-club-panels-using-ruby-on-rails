class AddBranchToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_reference :subscriptions, :branch, foreign_key: true
    add_column :subscriptions, :subscribe_for, :string
  end
end
