class RenameColumnAreaToAddress < ActiveRecord::Migration[5.2]
  def change
  	rename_column :banks, :area, :address
  end
end
