class ChangeColumn < ActiveRecord::Migration[5.2]
  def up
  	    rename_column :assets, :asset_type, :asset_type_id
  	    rename_column :assets, :brand, :brand_id
        change_column :assets, :asset_type_id, :integer
        change_column :assets, :brand_id, :integer
    end

    def down
        change_column :assets, :asset_type, :string
        change_column :assets, :brand, :string
    end    
end
