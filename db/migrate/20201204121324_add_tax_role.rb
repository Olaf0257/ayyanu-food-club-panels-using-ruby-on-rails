class AddTaxRole < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Tax")
  end

  def down
    Privilege.find_by(privilege_name: "Tax")&.destroy
  end
end
