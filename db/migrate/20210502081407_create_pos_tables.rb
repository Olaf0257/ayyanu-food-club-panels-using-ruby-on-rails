class CreatePosTables < ActiveRecord::Migration[5.2]
  def change
    create_table :pos_tables do |t|
      t.integer :no_of_chair
      t.string :name
      t.text :table_image
      t.references :branch, foreign_key: true

      t.timestamps
    end
  end
end
