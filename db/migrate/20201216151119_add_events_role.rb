class AddEventsRole < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Events")
  end

  def down
    Privilege.find_by(privilege_name: "Events")&.destroy
  end
end
