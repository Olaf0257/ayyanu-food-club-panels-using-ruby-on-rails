class AddIsPaidToOrder < ActiveRecord::Migration[5.1]
  def change    
    add_column :orders, :order_type, :string
    add_column :orders, :payment_mode, :string
    add_column :orders, :pickedup, :boolean, default: false
    add_column :orders, :is_delivered, :boolean, default: false
    add_column :orders, :is_paid, :boolean, default: false
    
  end 
end
