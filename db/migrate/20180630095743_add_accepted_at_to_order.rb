class AddAcceptedAtToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :accepted_at, :datetime
    add_column :orders, :pickedup_at, :datetime
    add_column :orders, :delivered_at, :datetime
  end
end
