class CreateKds < ActiveRecord::Migration[5.2]
  def change
    create_table :kds do |t|
      t.string :country_ids
      t.string :branch_ids
      t.string :name
      t.string :kds_type
      t.timestamps
    end
  end
end
