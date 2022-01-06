class CreateAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :addresses do |t|
      t.string :area
      t.string :address_type
      t.string :block
      t.string :street
      t.string :building
      t.string :floor
      t.string :apartment_number
      t.string :additional_direction
      t.string :contact
      t.string :landline
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
