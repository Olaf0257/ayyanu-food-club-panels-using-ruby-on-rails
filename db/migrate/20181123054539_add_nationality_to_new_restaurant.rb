class AddNationalityToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :cpr_number, :string
    add_column :new_restaurants, :owner_name, :string
    add_column :new_restaurants, :nationality, :string
  end
end
