class CreateZones < ActiveRecord::Migration[5.2]
  def change
    create_table :zones do |t|
      t.string :name, null: false
      t.string :name_ar, null: false
      t.references :country, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
