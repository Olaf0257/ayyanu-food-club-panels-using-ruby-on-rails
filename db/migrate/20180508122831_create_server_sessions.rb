class CreateServerSessions < ActiveRecord::Migration[5.1]
  def change
    create_table :server_sessions do |t|
      t.string :server_token
      t.references :auth, foreign_key: true

      t.timestamps
    end
  end
end
