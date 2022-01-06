class AddStatusToDocumentUploads < ActiveRecord::Migration[5.2]
  def change
    add_column :document_uploads, :status, :integer
  end
end
