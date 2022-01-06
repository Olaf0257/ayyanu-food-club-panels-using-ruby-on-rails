class ChangeTypeName < ActiveRecord::Migration[5.1]
  def change
  	rename_column :new_restaurant_images, :type, :doc_type
  end
end
