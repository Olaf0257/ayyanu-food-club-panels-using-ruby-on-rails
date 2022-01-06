class CreateReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :reviews do |t|
      t.string :review_type
      t.string :vote_type
      t.string :review_for

      t.timestamps
    end
  end
end
