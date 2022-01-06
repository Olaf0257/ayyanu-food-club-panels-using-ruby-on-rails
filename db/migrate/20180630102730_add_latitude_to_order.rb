class AddLatitudeToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :latitude, :string
    add_column :orders, :longitude, :string
  end
end
