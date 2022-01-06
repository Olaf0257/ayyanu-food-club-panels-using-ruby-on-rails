class CreateFamilyDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :family_details do |t|
      t.integer :employee_id
      t.string :name
      t.string :relation
      t.string :gender
      t.string :profession
      t.string :nationality
      t.string :address
      t.string :notes

      t.timestamps
    end
  end
end
