class CreateSessionDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :session_devices do |t|
      t.string :session_token
      t.string :device_type
      t.string :device_id
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
