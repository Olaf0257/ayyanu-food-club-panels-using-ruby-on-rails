class CreateRestaurantDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_documents do |t|
      t.string :doc_url
      t.references :restaurant, foreign_key: true

      t.timestamps
    end
  end
end
