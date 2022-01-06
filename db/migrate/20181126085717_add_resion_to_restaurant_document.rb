class AddResionToRestaurantDocument < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_documents, :is_approved, :boolean,default: false
    add_column :restaurant_documents, :is_rejected, :boolean,default: false
    add_column :restaurant_documents, :reject_reason, :text
  end
end
