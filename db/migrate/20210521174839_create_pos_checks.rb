class CreatePosChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :pos_checks do |t|
      t.string :check_id
      t.integer :no_of_guest
      t.integer :check_type
      t.references :pos_table, foreign_key: true

      t.timestamps
    end
  end
end
