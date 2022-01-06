class AddUserIdToOrder < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :user, foreign_key: true
    add_column :orders, :transporter_id, :integer
  end
end
