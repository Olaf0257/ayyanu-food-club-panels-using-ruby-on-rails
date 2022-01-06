class AddareatoEnterprise < ActiveRecord::Migration[5.2]
  def change
  	    add_column :enterprises, :area, :string
  end
end
