class AddTaxPercentageToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :tax_percentage, :float
  end
end
