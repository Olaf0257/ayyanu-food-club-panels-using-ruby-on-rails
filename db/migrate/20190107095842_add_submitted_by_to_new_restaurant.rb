class AddSubmittedByToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :submitted_by, :string
  end
end
