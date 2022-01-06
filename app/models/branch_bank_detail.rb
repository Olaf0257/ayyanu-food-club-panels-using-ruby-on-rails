class BranchBankDetail < ApplicationRecord
  belongs_to :branch

  validates :legal_name, :iban, :account_number, :beneficiary_address, :bank_address, :swift_code, :commercial_license, :civil_id, :commercial_license_file_id, :civil_id_file_id, :commercial_license_number, :commercial_license_issuing_country, :commercial_license_issuing_date, :commercial_license_expiry_date, :civil_id_number, :civil_id_issuing_country, :civil_id_issuing_date, :civil_id_expiry_date, :contact_title, :contact_first_name, :contact_last_name, :contact_email, :contact_country_code, :contact_mobile, :brand_name, :sector, :destination_id, presence: true

  def contact_full_name
    contact_title + " " + contact_first_name + " " + contact_middle_name.to_s + " " + contact_last_name
  end
end