class ChaneWorrentyAsDate < ActiveRecord::Migration[5.2]
  def up
        change_column :assets, :warranty, :date
    end

    def down
        change_column :assets, :warranty, :string
    end    
end
