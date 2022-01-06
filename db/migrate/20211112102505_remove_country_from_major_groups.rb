class RemoveCountryFromMajorGroups < ActiveRecord::Migration[5.2]
  def change
    remove_reference :major_groups, :country, foreign_key: true
    add_column :major_groups, :country_ids, :text
  end
end
