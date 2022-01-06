class CreateVendors < ActiveRecord::Migration[5.2]
  def change
    create_table :vendors do |t|
      t.string :company_name
      t.string :company_registration_no
      t.string :mobile_no
      t.string :phone_no
      t.integer :area_id
      t.string :country
      t.integer :country_id
      t.integer :user_id
      t.boolean :status

      t.timestamps
    end
  end
end
