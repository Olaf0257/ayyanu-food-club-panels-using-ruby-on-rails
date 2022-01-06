class AddMobileCodeAndLandlineCodeToVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :vendors, :mobile_code, :string
    add_column :vendors, :landline_code, :string
  end
end
