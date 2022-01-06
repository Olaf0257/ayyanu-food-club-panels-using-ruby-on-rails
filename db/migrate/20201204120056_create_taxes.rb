class CreateTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :taxes do |t|
      t.string :name, null: false
      t.float :percentage, null: false
      t.references :country, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
