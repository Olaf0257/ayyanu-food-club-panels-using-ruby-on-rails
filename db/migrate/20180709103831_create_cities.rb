class CreateCities < ActiveRecord::Migration[5.1]
  def change
    create_table :cities do |t|
      t.string :city
      t.string :state
      t.string :country

      t.timestamps
    end
  end
end
