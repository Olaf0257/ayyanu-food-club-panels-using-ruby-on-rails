class AddTitleArToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :title_ar, :string
  end
end
