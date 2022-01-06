class CreateKdsColors < ActiveRecord::Migration[5.2]
  def change
    create_table :kds_colors do |t|
      t.string :color
      t.integer :minutes
      t.references :restaurant, foreign_key: true

      t.timestamps
    end
  end
end
