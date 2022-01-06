class AddcolumntoKDs < ActiveRecord::Migration[5.2]
  def change
  	add_column :kds , :station_id , :integer
  end
end
