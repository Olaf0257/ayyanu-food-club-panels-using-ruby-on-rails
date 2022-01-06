class AddDineInTransporter < ActiveRecord::Migration[5.2]
  def up
    user = User.create(name: "Dine In Transporter", email: "dineintransporter@foodclube.com", contact: "", country_code: "")
    Auth.create_user_password(user, "123456", "transporter")
  end

  def down
    User.find_by(email: "dineintransporter@foodclube.com")&.destroy
  end
end
