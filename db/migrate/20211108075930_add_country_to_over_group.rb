class AddCountryToOverGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :over_groups, :country, foreign_key: true
    add_column :over_groups, :branch_ids, :string
  end
end
