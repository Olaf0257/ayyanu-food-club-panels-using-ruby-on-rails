class AddTempColumnsToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :temp_title, :string
    add_column :restaurants, :temp_title_ar, :string
  end
end
