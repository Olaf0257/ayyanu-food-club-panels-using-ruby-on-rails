class RenameStoreGroupIdToStoreTypeId < ActiveRecord::Migration[5.2]
  def change
    rename_column :stores, :store_group_id, :store_type_id
  end
end
