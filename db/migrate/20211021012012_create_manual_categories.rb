class CreateManualCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :manual_categories do |t|
      t.string :name
      t.integer :restaurant_id
      t.integer :created_by_id

      t.timestamps
    end
  end
end
