class AddDirectPointPercentageToServicefee < ActiveRecord::Migration[5.1]
  def change
    add_column :servicefees, :direct_point_percentage, :float,default: 10.0
    add_column :servicefees, :refferal_point_percentage, :float,default: 5.0
  	add_index :servicefees, :direct_point_percentage
  	add_index :servicefees, :refferal_point_percentage
  end
end
