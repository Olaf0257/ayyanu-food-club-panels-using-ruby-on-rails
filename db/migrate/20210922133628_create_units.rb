class CreateUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :units do |t|
      t.string :name
      t.string :consists_of
      t.string :base_unit
      t.references :restaurant, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
