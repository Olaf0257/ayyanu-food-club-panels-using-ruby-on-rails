class AddIndexToAddresses < ActiveRecord::Migration[5.1]
  def change
  	add_index :addresses, :coverage_area_id
  end
end
