class CreateEmployeePaymentDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :employee_payment_details do |t|
      t.integer :user_id
      t.string :bank_name
      t.string :account_type
      t.string :account_number
      t.string :ifsc_code
      t.string :branch_name

      t.timestamps
    end
  end
end
