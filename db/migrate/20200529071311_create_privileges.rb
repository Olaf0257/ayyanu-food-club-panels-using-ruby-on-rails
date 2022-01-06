class CreatePrivileges < ActiveRecord::Migration[5.1]
  def change
    create_table :privileges do |t|
      t.text :privilege_name, null: false
      t.timestamps
    end
  end
end
