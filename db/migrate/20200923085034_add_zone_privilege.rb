class AddZonePrivilege < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Zones")
  end

  def down
    Privilege.find_by(privilege_name: "Zones")&.destroy
  end
end
