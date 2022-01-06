class CreateGhostDeliveryUsers < ActiveRecord::Migration[5.2]
  def up
    DeliveryCompany.all.each do |company|
      user = company.users.find_or_create_by(name: "Food Club Driver", email: "foodclub_driver#{company.id}@foodclubapp.com", country_code: "", contact: "")
      user.auths.create(role: "transporter", password: "123456")
    end
  end

  def down
  end
end
