class RenameStoreGroupsToStoreTypes < ActiveRecord::Migration[5.2]
  def change
    rename_table :store_groups, :store_types
  end
end
