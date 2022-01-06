class AddBarcodeToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :barcode, :text
  end
end
