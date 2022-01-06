class CreateChapterEmpolyees < ActiveRecord::Migration[5.2]
  def change
    create_table :chapter_empolyees do |t|
      t.integer :chapter_id
      t.integer :user_id

      t.timestamps
    end
  end
end
