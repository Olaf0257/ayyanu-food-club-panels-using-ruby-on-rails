class AddNameToShifts < ActiveRecord::Migration[5.2]
  def change
    add_column :shifts, :name, :string
  end
end
