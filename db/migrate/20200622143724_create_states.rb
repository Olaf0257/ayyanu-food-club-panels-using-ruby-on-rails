class CreateStates < ActiveRecord::Migration[5.2]
  def change
    create_table :states do |t|
      t.string :name, null: false
      t.references :country, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
