class RemoveRestaurantVoteTypeFromOrderReview < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_reviews, :restaurant_review_title, :string
    remove_column :order_reviews, :restaurant_vote_type, :string
    remove_column :order_reviews, :transporter_review_title, :string
    remove_column :order_reviews, :transporter_vote_type, :string
    remove_column :order_reviews, :transporter_id, :integer
  end
end
