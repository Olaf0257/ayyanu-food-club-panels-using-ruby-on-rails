class AddCookedAtToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :cooked_at, :datetime
  end
end
