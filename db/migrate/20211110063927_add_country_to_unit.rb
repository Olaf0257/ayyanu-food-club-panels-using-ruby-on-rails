class AddCountryToUnit < ActiveRecord::Migration[5.2]
  def change
    add_reference :units, :country, foreign_key: true
    add_column :units, :branch_ids, :string
  end
end
