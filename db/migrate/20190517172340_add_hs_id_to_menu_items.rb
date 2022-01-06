class AddHsIdToMenuItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :hs_id, :integer
  
  end
end
