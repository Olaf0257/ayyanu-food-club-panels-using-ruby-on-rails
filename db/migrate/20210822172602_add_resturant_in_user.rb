class AddResturantInUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :restaurant_user_id, :integer
  end
end
