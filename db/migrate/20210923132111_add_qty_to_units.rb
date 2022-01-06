class AddQtyToUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :units, :qty, :string
    add_column :units, :other_unit, :string
  end
end
