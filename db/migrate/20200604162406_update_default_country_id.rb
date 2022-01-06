class UpdateDefaultCountryId < ActiveRecord::Migration[5.1]
  def change
    Restaurant.where(country_id: nil).update_all(country_id: 15)
    NewRestaurant.where(country_id: nil).update_all(country_id: 15)
    Category.where(country_id: nil).update_all(country_id: 15)
  end
end
