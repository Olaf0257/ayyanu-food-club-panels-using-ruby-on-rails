class AddApprovedAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :approved_at, :datetime
    add_column :users, :rejected_at, :datetime
  end
end
