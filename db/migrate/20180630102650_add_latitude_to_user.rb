class AddLatitudeToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :latitude, :string
    add_column :users, :longitude, :string
  end
end
