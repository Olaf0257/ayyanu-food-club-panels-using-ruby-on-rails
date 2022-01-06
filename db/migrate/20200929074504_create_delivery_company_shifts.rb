class CreateDeliveryCompanyShifts < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_company_shifts do |t|
      t.string :start_time, null: false
      t.string :end_time, null: false
      t.integer :day, null: false
      t.references :delivery_company, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
