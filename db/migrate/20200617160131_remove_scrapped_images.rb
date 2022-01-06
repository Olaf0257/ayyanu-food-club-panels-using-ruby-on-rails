class RemoveScrappedImages < ActiveRecord::Migration[5.2]
  def up
    MenuItem.where("item_image like ?", "%scrap_menu_item_image%").update_all(item_image: nil)
  end

  def down
  end
end
