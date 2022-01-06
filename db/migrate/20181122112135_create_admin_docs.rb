class CreateAdminDocs < ActiveRecord::Migration[5.1]
  def change
    create_table :admin_docs do |t|
      t.string :doc_title
      t.string :contract_url

      t.timestamps
    end
  end
end
