class CreateAddRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :add_requests do |t|
      t.string :position
      t.string :place
      t.string :title
      t.string :description
      t.float :amount
      t.boolean :is_accepted,default: false
      t.string :transaction_id
      t.references :branch, foreign_key: true
      t.references :coverage_area, foreign_key: true
      t.references :week, foreign_key: true
      t.string :start_year
      t.string :end_year

      t.timestamps
    end
  end
end
