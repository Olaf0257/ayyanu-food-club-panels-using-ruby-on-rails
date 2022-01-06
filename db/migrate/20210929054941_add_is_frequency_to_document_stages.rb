class AddIsFrequencyToDocumentStages < ActiveRecord::Migration[5.2]
  def change
    add_column :document_stages, :is_frequency, :boolean, :default => false
  end
end
