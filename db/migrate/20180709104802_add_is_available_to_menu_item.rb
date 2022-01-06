class AddIsAvailableToMenuItem < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :is_available, :boolean,default: true
  end
end
