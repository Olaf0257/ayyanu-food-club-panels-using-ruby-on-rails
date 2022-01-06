class AddColumnCountryIdAndFloorNameToPosTables < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_tables, :country_name, :string
    add_column :pos_tables, :floor_name, :string
  end
end
