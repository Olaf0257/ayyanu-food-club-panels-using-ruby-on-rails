class CreateStages < ActiveRecord::Migration[5.2]
  def change
    create_table :stages do |t|
      t.boolean :bank, :default => false
      t.boolean :enabled, :default => false
      t.boolean :date, :default => false
      t.boolean :depositor_number, :default => false
      t.boolean :account_name, :default => false
      t.boolean :account_number,:default => false
      t.boolean :note,:default => false
      t.boolean :serial_number, :default => false
      t.boolean :vendor_name,:default => false
      t.boolean :autorize_person,:default => false
      t.boolean :employee_name,:default => false
      t.boolean :vendor_number, :default => false
      t.boolean :card_types, :default => false
      t.boolean :number_of_machine, :default => false
      t.boolean :deduction_type,:default => false
      t.boolean :amounts,:default => false
      t.boolean :exchange_name,:default => false
      t.boolean :person_recieve,:default => false
      t.string :name,  :default => ""
      t.timestamps
    end
  end
end
