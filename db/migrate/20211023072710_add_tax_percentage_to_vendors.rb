class AddTaxPercentageToVendors < ActiveRecord::Migration[5.2]
  def change
    remove_column :vendors, :tax_percentage
    add_column :vendors, :tax_percentage, :string
  end
end
