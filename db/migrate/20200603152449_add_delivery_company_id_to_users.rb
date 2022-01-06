class AddDeliveryCompanyIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_reference :users, :delivery_company, foreign_key: true, index: true
  end
end
