class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :contact
      t.string :country_code

      t.timestamps
    end
  end
end
