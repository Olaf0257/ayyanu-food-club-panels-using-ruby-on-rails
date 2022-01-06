class CreateRatings < ActiveRecord::Migration[5.1]
  def change
    create_table :ratings do |t|
      t.string :review_title
      t.string :review_description
      t.string :rating
      t.references :user, foreign_key: true
      t.references :branch, foreign_key: true

      t.timestamps
    end
  end
end
