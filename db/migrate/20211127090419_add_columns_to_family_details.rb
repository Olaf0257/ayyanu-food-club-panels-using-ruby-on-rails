class AddColumnsToFamilyDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :family_details, :country_ids, :string
    add_column :family_details, :location, :string
  end
end
