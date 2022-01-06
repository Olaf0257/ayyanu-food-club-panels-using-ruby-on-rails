class AddApprovedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :approval_status, :string, default: 'pending'
    add_column :users, :rejected_reason, :string
  end
end
