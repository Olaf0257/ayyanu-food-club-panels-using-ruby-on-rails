class AddMotherCompantNameToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :mother_company_name, :string
    add_column :new_restaurants, :serving, :string
    add_column :new_restaurants, :road_number, :string
    add_column :new_restaurants, :building, :string
    add_column :new_restaurants, :unit_number, :string
    add_column :new_restaurants, :floor, :string
    add_column :new_restaurants, :other_user_email, :string
    add_column :new_restaurants, :other_user_name, :string
    add_column :new_restaurants, :other_user_role, :string
   end
end
