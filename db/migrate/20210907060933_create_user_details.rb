class CreateUserDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :user_details do |t|
      t.integer :employement_type
      t.string :reporting_to
      t.integer :probation_period
      t.datetime :confirmation_date
      t.string :emergency_contact_name
      t.string :emergency_contact_number
      t.string :father_name
      t.string :spouse_name
      t.string :designation
      t.string :department
      t.string :location
      t.string :grade
      t.boolean :include_pf
      t.string :pf_number
      t.string :uan_number
      t.string :pf_excess_contribution
      t.boolean :include_esi
      t.string :esi_number
      t.boolean :include_lwf
      t.string :payment_mode
      t.string :bank_name
      t.string :account_type
      t.string :account_number
      t.string :ifsc
      t.string :branch_name
      t.string :dd_payable_at
      t.string :total_experience
      t.string :last_epmloyer
      t.date :contract_expiry_date
      t.integer :number_of_annual_leaves
      t.date :vacation_date
      t.string :deployment_branch
      t.string :cpr_identity_number
      t.date :cpr_identity_expiry
      t.string :vehicle_type
      t.string :current_address
      t.string :passport_number
      t.date :passport_expiry
      t.date :vaccine_date
      t.date :booster_dose_date
      t.string :visa_number
      t.date :visa_expiry
      t.integer :notice_period_days
      t.integer :employee_weekdays
      t.bigint :detailable_id
      t.string :detailable_type

      t.timestamps
    end
  end
end
