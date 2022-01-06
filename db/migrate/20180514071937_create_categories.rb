class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.string :title
      t.string :icon
      t.string :color

      t.timestamps
    end
  end
end
