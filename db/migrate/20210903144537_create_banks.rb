class CreateBanks < ActiveRecord::Migration[5.2]
  def change
    create_table :banks do |t|
      t.string :name
      t.string :account_number
      t.string :swift_code
      t.string :ifsc
      t.string :iban
      t.string :area
      t.string :block
      t.string :road_no
      t.string :building
      t.string :floor
      t.text :additional_direction
      t.string :phone

      t.timestamps
    end
  end
end
