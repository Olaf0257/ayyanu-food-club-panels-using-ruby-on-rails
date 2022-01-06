class CreateDistricts < ActiveRecord::Migration[5.2]
  def change
    create_table :districts do |t|
      t.string :name, null: false
      t.references :state, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
