class RemoveCountryFromItemGroups < ActiveRecord::Migration[5.2]
  def change
    remove_reference :item_groups, :country, foreign_key: true
    add_column :item_groups, :country_ids, :text
  end
end
