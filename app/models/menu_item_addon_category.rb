class MenuItemAddonCategory < ApplicationRecord
  belongs_to :item_addon_category
  belongs_to :menu_item
end
