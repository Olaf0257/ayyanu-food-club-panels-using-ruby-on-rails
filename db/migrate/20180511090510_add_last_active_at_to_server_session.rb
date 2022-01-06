class AddLastActiveAtToServerSession < ActiveRecord::Migration[5.1]
  def change
    add_column :server_sessions, :last_active_at, :datetime,default: DateTime.now
  end
end
