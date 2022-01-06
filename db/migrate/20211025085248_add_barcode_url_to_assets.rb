class AddBarcodeUrlToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :barcode_url, :text
  end
end
