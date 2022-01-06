class AddCountryToMajorGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :major_groups, :country, foreign_key: true
    add_column :major_groups, :branch_ids, :string
  end
end
