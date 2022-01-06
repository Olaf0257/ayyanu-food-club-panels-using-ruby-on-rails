class AddCountryToItemGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :item_groups, :country, foreign_key: true
    add_column :item_groups, :branch_ids, :string
  end
end
