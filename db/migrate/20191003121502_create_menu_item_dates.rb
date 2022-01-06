class CreateMenuItemDates < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_item_dates do |t|
      t.references :menu_item, foreign_key: true
      t.date :menu_date, index: true
      t.timestamps
    end
  end
end
