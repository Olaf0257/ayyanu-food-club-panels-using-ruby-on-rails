class AddBarcodeUrlToDocumentsUpload < ActiveRecord::Migration[5.2]
  def change
    add_column :document_uploads, :barcode_url, :text
  end
end
