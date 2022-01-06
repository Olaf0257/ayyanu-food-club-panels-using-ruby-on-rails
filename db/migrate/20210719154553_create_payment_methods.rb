class CreatePaymentMethods < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_methods do |t|
      t.string :name
      t.boolean :is_enabled, default: true
      t.integer :created_by_id
      t.integer :last_updated_by_id

      t.timestamps
    end
  end
end
