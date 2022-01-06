class CreateChapters < ActiveRecord::Migration[5.2]
  def change
    create_table :chapters do |t|
      t.integer :user_id
      t.integer :manual_id
      t.string :chapter_title
      t.text :body
      t.integer :restaurant_id
      t.integer :created_by_id
      t.timestamps
    end
  end
end

