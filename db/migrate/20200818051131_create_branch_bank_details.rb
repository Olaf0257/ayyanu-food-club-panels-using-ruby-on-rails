class CreateBranchBankDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :branch_bank_details do |t|
      t.string :legal_name, null: false
      t.string :iban, null: false
      t.string :account_number, null: false
      t.string :beneficiary_address, null: false
      t.string :bank_address, null: false
      t.string :swift_code, null: false
      t.string :commercial_license, null: false
      t.string :civil_id, null: false
      t.string :commercial_license_file_id, null: false
      t.string :civil_id_file_id, null: false
      t.string :commercial_license_number, null: false
      t.string :commercial_license_issuing_country, null: false
      t.string :commercial_license_issuing_date, null: false
      t.string :commercial_license_expiry_date, null: false
      t.string :civil_id_number, null: false
      t.string :civil_id_issuing_country, null: false
      t.string :civil_id_issuing_date, null: false
      t.string :civil_id_expiry_date, null: false
      t.string :contact_title, null: false
      t.string :contact_first_name, null: false
      t.string :contact_middle_name
      t.string :contact_last_name, null: false
      t.string :contact_email, null: false
      t.string :contact_country_code, null: false
      t.string :contact_mobile, null: false
      t.string :brand_name, null: false
      t.string :sector, null: false
      t.string :destination_id, null: false
      t.references :branch, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
