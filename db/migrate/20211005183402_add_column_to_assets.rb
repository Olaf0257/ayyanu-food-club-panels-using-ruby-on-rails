class AddColumnToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :location_available, :string
    add_column :assets, :brand, :string
    add_column :assets, :model, :string
    add_column :assets, :serial_number, :string
    add_column :assets, :purchase_date, :date
    add_column :assets, :invoice_number, :string
    add_column :assets, :asset_pic_upload, :string
    add_column :assets, :current_value, :string
    add_column :assets, :original_value, :string
    add_column :assets, :warranty, :string
  end
end
