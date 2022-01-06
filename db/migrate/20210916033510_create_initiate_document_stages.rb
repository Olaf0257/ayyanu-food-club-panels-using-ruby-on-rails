class CreateInitiateDocumentStages < ActiveRecord::Migration[5.2]
  def change
    create_table :initiate_document_stages do |t|
      t.integer :document_stage_id
      t.integer :stage_id

      t.timestamps
    end
  end
end
