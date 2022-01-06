class RenameStoreTypeToStoreCategory < ActiveRecord::Migration[5.2]
  def change
    rename_column :stores, :store_type, :store_category
  end
end
