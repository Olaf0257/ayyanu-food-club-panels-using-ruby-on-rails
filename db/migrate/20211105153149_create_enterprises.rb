class CreateEnterprises < ActiveRecord::Migration[5.2]
  def change
    create_table :enterprises do |t|
      t.string :name
      t.string :person_name
      t.string :contact_number
      t.string :role
      t.string :email
      t.references :coverage_area, foreign_key: true
      t.boolean :is_approved
      t.boolean :is_rejected
      t.string :rejected_reason
      t.string :cr_number
      t.string :bank_name
      t.integer :bank_account
      t.string :cpr_number
      t.string :owner_name
      t.string :nationality
      t.string :submitted_by
      t.string :delivery_status
      t.string :branch_no
      t.string :enterprise_name
      t.string :road_number
      t.string :building
      t.string :unit_number
      t.string :floor
      t.string :other_user_email
      t.string :other_user_name
      t.string :other_user_role
      t.string :other_user_role
      t.string :block
      t.integer :restaurant_id
      t.integer :country_id
      t.datetime :rejected_at

      t.timestamps
    end
  end
end
