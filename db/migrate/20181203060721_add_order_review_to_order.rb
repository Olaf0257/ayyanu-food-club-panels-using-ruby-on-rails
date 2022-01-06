class AddOrderReviewToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :order_review, :boolean,default: false
    add_column :orders, :review_cancel, :boolean,default: false
  end
end
