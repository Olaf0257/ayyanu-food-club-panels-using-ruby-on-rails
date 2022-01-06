class AddEmergencyContactCountryCodeToUserDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :user_details, :emergency_contact_countrycode, :string
  end
end
