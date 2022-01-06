class AddDistrictPrivilege < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Districts")
  end

  def down
    Privilege.find_by(privilege_name: "Districts")&.destroy
  end
end
