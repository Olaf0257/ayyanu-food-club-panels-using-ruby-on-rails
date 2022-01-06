class CreateShifts < ActiveRecord::Migration[5.2]
  def change
    create_table :shifts do |t|
      t.references :restaurant, foreign_key: true
      t.references :user, foreign_key: true
      t.string :start_time
      t.string :end_time
      t.integer :day

      t.timestamps
    end
  end
end
