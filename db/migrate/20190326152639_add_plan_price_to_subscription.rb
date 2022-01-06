class AddPlanPriceToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :plan_price, :float,default: "5.000"
  end
end
