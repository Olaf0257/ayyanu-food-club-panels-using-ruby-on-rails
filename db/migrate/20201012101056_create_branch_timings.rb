class CreateBranchTimings < ActiveRecord::Migration[5.2]
  def change
    create_table :branch_timings do |t|
      t.string :opening_time, null: false
      t.string :closing_time, null: false
      t.integer :day, null: false
      t.references :branch, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
