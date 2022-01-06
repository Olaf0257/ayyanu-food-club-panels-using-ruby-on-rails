class AddRestaurantIdToDocumentStages < ActiveRecord::Migration[5.2]
  def change
    add_column :document_stages, :restaurant_id, :integer
  end
end
