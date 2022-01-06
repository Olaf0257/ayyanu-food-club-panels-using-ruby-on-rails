class AddHiddenToRatings < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings, :order_hidden, :boolean, null: false, default: false
    add_column :ratings, :driver_hidden, :boolean, null: false, default: false
  end
end
