class AddTutorialPrivileges < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Tutorials")
  end

  def down
    Privilege.find_by(privilege_name: "Tutorials").destroy
  end
end
