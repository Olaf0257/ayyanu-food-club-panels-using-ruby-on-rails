class AddCurrencyToSalaries < ActiveRecord::Migration[5.2]
  def change
    add_column :salaries, :currency, :string
    add_column :salaries, :housing, :decimal
    add_column :salaries, :transportation, :decimal
    add_column :salaries, :meal, :decimal
    add_column :salaries, :mobile_allowance, :decimal
    add_column :salaries, :insurance, :decimal
    add_column :salaries, :visa_charges, :decimal
    add_column :salaries, :lmra, :decimal
  end
end
