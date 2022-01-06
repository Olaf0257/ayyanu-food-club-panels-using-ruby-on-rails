class CreateEnterpriseDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :enterprise_documents do |t|
      t.string :doc_url
      t.integer :enterprise_id
      t.boolean :is_approved, default: false
      t.boolean :is_rejected, default: false
      t.boolean :reject_reason

      t.timestamps
    end
  end
end
