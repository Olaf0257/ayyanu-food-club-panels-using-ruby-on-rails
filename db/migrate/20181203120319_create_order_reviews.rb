class CreateOrderReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :order_reviews do |t|
      t.references :user, foreign_key: true
      t.references :restaurant, foreign_key: true
      t.references :order, foreign_key: true
      t.integer :transporter_id
      t.string :restaurant_review_title
      t.string :restaurant_vote_type
      t.string :transporter_review_title
      t.string :transporter_vote_type
      t.text :order_experience

      t.timestamps
    end
  end
end
