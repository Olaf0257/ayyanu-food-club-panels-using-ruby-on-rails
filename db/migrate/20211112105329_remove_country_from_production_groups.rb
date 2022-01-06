class RemoveCountryFromProductionGroups < ActiveRecord::Migration[5.2]
  def change
    remove_reference :production_groups, :country, foreign_key: true
    add_column :production_groups, :country_ids, :text
  end
end
