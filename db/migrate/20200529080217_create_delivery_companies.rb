class CreateDeliveryCompanies < ActiveRecord::Migration[5.1]
  def change
    create_table :delivery_companies do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :contact_no, null: false
      t.string :address1, null: false
      t.string :address2
      t.string :address3
      t.string :agreement
      t.integer :country_id, null: false
      t.boolean :active, null: false, default: true
      t.boolean :approved, null: false, default: false
      t.boolean :rejected, null: false, default: false

      t.timestamps
    end
  end
end
