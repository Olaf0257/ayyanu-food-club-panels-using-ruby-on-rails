class CreateRolePrivileges < ActiveRecord::Migration[5.1]
  def change
    create_table :role_privileges do |t|
      t.belongs_to :role, null: false
      t.belongs_to :privilege, null: false
      t.timestamps
    end
  end
end
