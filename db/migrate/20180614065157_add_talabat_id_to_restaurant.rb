class AddTalabatIdToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :talabat_id, :string
    add_column :restaurants, :logo, :string
  end
end
