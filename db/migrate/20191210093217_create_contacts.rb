class CreateContacts < ActiveRecord::Migration[5.1]
  def change
    create_table :contacts do |t|
      t.string :email
      t.text :message
      t.string :full_name

      t.timestamps
    end
  end
end
