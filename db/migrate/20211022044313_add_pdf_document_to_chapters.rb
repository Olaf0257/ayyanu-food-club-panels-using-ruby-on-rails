class AddPdfDocumentToChapters < ActiveRecord::Migration[5.2]
  def change
    add_column :chapters, :pdf_document, :string
    remove_column :chapters, :body, :text
  end
end
