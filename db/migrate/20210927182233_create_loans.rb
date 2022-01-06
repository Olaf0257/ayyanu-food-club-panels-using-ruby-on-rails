class CreateLoans < ActiveRecord::Migration[5.2]
  def change
    create_table :loans do |t|
      t.integer :user_id
      t.integer :department_id
      t.integer :designation_id
      t.date :loan_date
      t.decimal :amount
      t.string :deducted_from
      t.decimal :interest_rate
      t.date :created_date
      t.integer :installments
      t.integer :loan_type_id
      t.integer :restaurant_id
      t.string :account_number

      t.timestamps
    end
  end
end
