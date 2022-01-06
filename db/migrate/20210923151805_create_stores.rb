class CreateStores < ActiveRecord::Migration[5.2]
  def change
    create_table :stores do |t|
      t.string :name
      t.string :phone
      t.string :store_type
      t.references :tax, foreign_key: true
      t.references :user, foreign_key: true
      t.references :store_group, foreign_key: true
      t.string :restaurant_branch_list
      t.string :address
      t.string :block
      t.string :road_no
      t.string :building
      t.string :floor
      t.text :additional_direction
      t.integer :city_id
      t.integer :country_id
      t.integer :area_id

      t.timestamps
    end
  end
end
