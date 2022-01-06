class ChangeSalaryColumnTypes < ActiveRecord::Migration[5.2]
  def change
    drop_table :salaries
    create_table :salaries do |t|
      t.decimal  :basic_salary, precision: 30, :scale => 3
      t.decimal  :gosi_percentage, precision: 30, :scale => 3
      t.decimal  :hiring_fees_deduction, precision: 30, :scale => 3
      t.decimal  :indemnity_days
      t.decimal  :full_hra, precision: 30, :scale => 3
      t.decimal  :full_conveyance, precision: 30, :scale => 3
      t.decimal  :full_da, precision: 30, :scale => 3
      t.decimal  :full_special_allowence, precision: 30, :scale => 3
      t.decimal  :monthly_ctc, precision: 30, :scale => 3
      t.decimal  :annual_ctc, precision: 30, :scale => 3
      t.decimal  :salary_revise, precision: 30, :scale => 3
      t.decimal  :family_visa_charges, precision: 30, :scale => 3
      t.decimal  :health_check_charges, precision: 30, :scale => 3
      t.decimal  :housing_allowance, precision: 30, :scale => 3
      t.decimal  :transportation_allowance, precision: 30, :scale => 3
      t.decimal  :meal_allowance, precision: 30, :scale => 3
      t.decimal  :mobile_allowance, precision: 30, :scale => 3
      t.decimal  :visa_charges, precision: 30, :scale => 3
      t.integer  :user_id
      t.integer  :lmra_charges
      t.timestamps
    end
  end
end
