class AddPackingRatingToOrderReview < ActiveRecord::Migration[5.1]
  def change
    add_column :order_reviews, :packing_rate, :integer , default: 0
    add_column :order_reviews, :value_for_money_rate, :integer , default: 0
    add_column :order_reviews, :delivery_time_rate, :integer , default: 0
    add_column :order_reviews, :quality_of_food_rate, :integer , default: 0
  end
end
