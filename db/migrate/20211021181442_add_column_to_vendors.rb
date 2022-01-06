class AddColumnToVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :vendors, :address, :string
    add_column :vendors, :company_registration_expiry_date, :date
    add_column :vendors, :tax_percentage, :float
    add_column :vendors, :name_of_company_representative, :string
  end
end
