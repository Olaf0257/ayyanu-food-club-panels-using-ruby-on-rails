class AddCountryToProductionGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :production_groups, :country, foreign_key: true
    add_column :production_groups, :branch_ids, :string
  end
end
