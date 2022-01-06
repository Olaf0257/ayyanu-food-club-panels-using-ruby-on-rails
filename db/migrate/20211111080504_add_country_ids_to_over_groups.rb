class AddCountryIdsToOverGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :over_groups, :country_ids, :string
  end
end
