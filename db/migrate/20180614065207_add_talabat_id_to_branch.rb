class AddTalabatIdToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :talabat_id, :string
    add_column :branches, :delivery_time, :string
    add_column :branches, :delivery_charges, :string
    add_column :branches, :cash_on_delivery, :boolean, default: false
    add_column :branches, :accept_cash, :boolean, default: false
    add_column :branches, :accept_card, :boolean, default: false
    add_column :branches, :image, :string
    add_column :branches, :daily_timing, :string
    add_column :branches, :min_order_amount, :string
  end
end
