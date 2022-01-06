class AddIsSettledToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :is_settled,:boolean ,default: false
    add_column :orders, :settled_at, :datetime
  end
end
