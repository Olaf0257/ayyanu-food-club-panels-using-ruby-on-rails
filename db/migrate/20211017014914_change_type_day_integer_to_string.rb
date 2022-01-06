class ChangeTypeDayIntegerToString < ActiveRecord::Migration[5.2]
 def up
        change_column :shifts, :day, :string
    end

    def down
        change_column :shift, :day, :integer
    end
end
