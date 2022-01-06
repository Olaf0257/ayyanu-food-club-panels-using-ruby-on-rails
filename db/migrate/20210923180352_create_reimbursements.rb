class CreateReimbursements < ActiveRecord::Migration[5.2]
  def change
    create_table :reimbursements do |t|
      t.integer :user_id
      t.integer :reimbursement_type_id
      t.date :reimbursement_date
      t.decimal :amount
      t.string :remarks
      t.string :status
      t.integer :created_by_id

      t.timestamps
    end
  end
end
