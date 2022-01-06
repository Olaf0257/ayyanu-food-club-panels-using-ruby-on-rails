class AddDeliveryCompanyIdToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_reference :notifications, :delivery_company, index: true, foreign_key: true
  end
end
