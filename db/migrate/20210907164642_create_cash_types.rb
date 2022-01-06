class CreateCashTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_types do |t|
      t.float :amount
      t.references :restaurant, foreign_key: true
      t.boolean :is_enabled, default: true
      t.integer :created_by_id
      t.integer :last_updated_by_id

      t.timestamps
    end
  end
end
