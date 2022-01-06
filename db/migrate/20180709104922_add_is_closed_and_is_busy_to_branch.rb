class AddIsClosedAndIsBusyToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :is_closed, :boolean,default: false
    add_column :branches, :is_busy, :boolean,default: false
  end
end
