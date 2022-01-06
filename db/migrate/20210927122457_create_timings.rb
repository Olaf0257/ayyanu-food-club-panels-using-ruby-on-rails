class CreateTimings < ActiveRecord::Migration[5.2]
  def change
    create_table :timings do |t|
      t.string :opening_time
      t.string :closing_time
      t.integer :day

      t.timestamps
    end
  end
end
