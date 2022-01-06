class AddFixedChargePercentageToBranches < ActiveRecord::Migration[5.2]
  def change
    add_column :branches, :fixed_charge_percentage, :float
    add_column :branches, :max_fixed_charge, :float
    add_column :orders, :fixed_fc_charge, :float
  end
end
