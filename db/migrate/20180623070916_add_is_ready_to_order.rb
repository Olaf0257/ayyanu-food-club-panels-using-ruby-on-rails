class AddIsReadyToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :is_ready, :boolean,default: false
  end
end
