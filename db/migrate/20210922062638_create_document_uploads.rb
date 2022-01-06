class CreateDocumentUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :document_uploads do |t|
      t.integer :bank_id 
      t.date :date 
      t.string :depositor_number
      t.string :name_of_depositor_id 
      t.integer :account_name 
      t.integer :account_number
      t.string :note
      t.string :serial_number
      t.string :image  
      t.integer :vendor_id
      t.integer :authorize_id
      t.integer :employee_name
      t.string :vendor_number 
      t.integer :card_type_id
      t.integer :number_of_machine 
      t.string :deduction_type
      t.integer :amounts
      t.string :exchange_name
      t.integer :person_recieve_id
      t.string :name
      t.integer :document_stage_id
      t.integer :stage_id    
      t.timestamps	
    end
  end
end
