class CreateSalaries < ActiveRecord::Migration[5.2]
  def change
    create_table :salaries do |t|
      t.string  :basic_salary
      t.string  :allowences
      t.string  :gosi_percentage
      t.string  :hiring_fees_deduction
      t.string  :indemnity_days
      t.string  :airplane_charges
      t.string  :full_hra
      t.string  :full_conveyance
      t.string  :full_da
      t.string  :full_special_allowence
      t.string  :monthly_ctc
      t.string  :annual_ctc
      t.string  :salary_revise
    end
  end
end
