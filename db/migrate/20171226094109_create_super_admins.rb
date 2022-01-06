class CreateSuperAdmins < ActiveRecord::Migration[5.1]
  def change
    create_table :super_admins do |t|
      t.string :admin_name
      t.string :email
      t.string :password_digest
      t.string :image

      t.timestamps
    end
  end
end
