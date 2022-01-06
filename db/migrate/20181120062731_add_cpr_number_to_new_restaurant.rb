class AddCprNumberToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :cr_number, :string
    add_column :new_restaurants, :bank_name, :string
    add_column :new_restaurants, :bank_account, :string
  end
end
