class CreateDocumentStages < ActiveRecord::Migration[5.2]
  def change
    create_table :document_stages do |t|
      t.string :name
      t.integer :account_type_id
      t.integer :account_category_id
      t.string :frequency
      t.integer :stage_id
      t.integer :created_by_id
      t.timestamps
    end
  end
end
