class ChangeTableReimbersmentsToReimbursements < ActiveRecord::Migration[5.2]
  def change
    drop_table :reimbersments
    create_table :reimbursement_types do |t|
      t.string :name
    end
  end
end
