class CreateBudgets < ActiveRecord::Migration[5.1]
  def change
    create_table :budgets do |t|
      t.float :amount
      t.string :start_date
      t.string :end_date
      t.references :branch, foreign_key: true
      t.timestamps
    end
  end
end
