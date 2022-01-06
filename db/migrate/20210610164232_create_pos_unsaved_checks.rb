class CreatePosUnsavedChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :pos_unsaved_checks do |t|
      t.string :check_id
      t.integer :no_of_guest
      t.references :pos_table
      t.integer :check_status
      t.integer :check_type
      t.integer :current_seat_no
      t.boolean :is_new_merged, default: false
      t.integer :parent_unsaved_check_id
      t.references :branch, foreign_key: true
      t.references :pos_check, foreign_key: true

      t.timestamps
    end
  end
end
