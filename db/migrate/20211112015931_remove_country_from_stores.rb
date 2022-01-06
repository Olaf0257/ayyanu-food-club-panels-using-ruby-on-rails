class RemoveCountryFromStores < ActiveRecord::Migration[5.2]
  def change
    remove_column :stores, :country_id
    rename_column :stores, :restaurant_branch_list, :branch_ids
    add_column :stores, :country_ids, :text
  end
end
