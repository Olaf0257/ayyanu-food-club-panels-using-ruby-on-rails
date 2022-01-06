class AddIsAcceptedAndIsRejectedToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :is_accepted, :boolean,default: false
    add_column :orders, :is_rejected, :boolean,default: false
  end
end
