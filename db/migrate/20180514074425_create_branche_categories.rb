class CreateBrancheCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :branch_categories do |t|
      t.references :category, foreign_key: true
      t.references :branch, foreign_key: true

      t.timestamps
    end
  end
end
