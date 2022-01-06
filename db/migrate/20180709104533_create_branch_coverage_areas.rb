class CreateBranchCoverageAreas < ActiveRecord::Migration[5.1]
  def change
    create_table :branch_coverage_areas do |t|
      t.string :delivery_charges
      t.string :fooddelivey_charges
      t.string :minimum_amount
      t.string :delivery_time
      t.string :daily_open_at
      t.string :daily_closed_at
      t.boolean :is_closed,default: false
      t.boolean :is_busy,default: false
      t.references :branch, foreign_key: true
      t.references :coverage_area, foreign_key: true

      t.timestamps
    end
  end
end
