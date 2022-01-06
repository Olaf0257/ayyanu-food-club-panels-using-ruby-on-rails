class AddCountryCodeToFamilyDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :family_details, :country_code, :string
    change_column :user_details, :include_lwf, :string
    change_column :user_details, :pan_number, :string
    rename_column :employee_payment_details , :bank_name, :bank_id
    change_column :employee_payment_details , :bank_id, :integer
  end
end
