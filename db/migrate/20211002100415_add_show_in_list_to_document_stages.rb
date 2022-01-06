class AddShowInListToDocumentStages < ActiveRecord::Migration[5.2]
  def change
    add_column :document_stages, :show_in_list, :boolean, default: false
  end
end
