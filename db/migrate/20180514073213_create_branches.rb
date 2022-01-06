class CreateBranches < ActiveRecord::Migration[5.1]
  def change
    create_table :branches do |t|
      t.string :address
      t.string :city
      t.string :zipcode
      t.string :state
      t.string :country
      t.string :latitude
      t.string :longitude
      t.references :restaurant, foreign_key: true

      t.timestamps
    end
  end
end
