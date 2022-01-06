class ChangeDataTypeForBaseUnit < ActiveRecord::Migration[5.2]
  def change
    change_column :articles, :base_unit, :integer
  end
end
