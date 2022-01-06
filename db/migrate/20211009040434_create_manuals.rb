class CreateManuals < ActiveRecord::Migration[5.2]
  def change
    create_table :manuals do |t|
      t.string :name
      t.integer :restaurant_id
      t.integer :created_by_id

      t.timestamps
    end
  end
end
