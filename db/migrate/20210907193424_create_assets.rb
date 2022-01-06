class CreateAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :assets do |t|
      t.integer :employee_id
      t.string :asset_type
      t.date :valid_till
      t.date :returned_on
      t.string :remarks

      t.timestamps
    end
  end
end
