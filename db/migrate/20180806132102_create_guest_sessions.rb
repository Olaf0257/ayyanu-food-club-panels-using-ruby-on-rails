class CreateGuestSessions < ActiveRecord::Migration[5.1]
  def change
    create_table :guest_sessions do |t|
      t.string :guest_token
      t.string :device_id
      t.string :device_type

      t.timestamps
    end
  end
end
