class AddOrderToRating < ActiveRecord::Migration[5.1]
  def change
    add_reference :ratings, :order, foreign_key: true
  end
end
