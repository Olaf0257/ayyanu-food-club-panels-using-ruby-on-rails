class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.string :message
      t.string :notification_type
      t.boolean :status,default: false
      t.references :user, foreign_key: true
      t.string :receiver_id
      t.references :order, foreign_key: true
      t.string :admin_id
      t.boolean :seen_by_admin,default: false

      t.timestamps
    end
  end
end
