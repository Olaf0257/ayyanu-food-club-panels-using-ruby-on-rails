class Addcountryidstouserdetails < ActiveRecord::Migration[5.2]
  def change
  	add_column :user_details, :country_ids, :string
  end
end
