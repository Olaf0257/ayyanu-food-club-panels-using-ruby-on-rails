class AddIsSubscribeToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :unsubscribe_date, :date
    add_column :subscriptions, :is_subscribe, :boolean,default: true
  end
end
