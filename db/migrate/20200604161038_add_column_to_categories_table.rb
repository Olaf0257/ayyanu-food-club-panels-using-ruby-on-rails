class AddColumnToCategoriesTable < ActiveRecord::Migration[5.1]
  def change
    add_column :categories, :country_id, :integer
  end
end
