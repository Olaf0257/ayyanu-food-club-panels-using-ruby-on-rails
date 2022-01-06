class Ingredient < ApplicationRecord
  belongs_to :item_group, optional: true
  belongs_to :recipe_group, optional: true
  belongs_to :ingredientable, polymorphic: true
  belongs_to :recipe

  PORTION_UNIT = {'each' => ['STK', 'LT', 'PORT'], 'kilogram' => ['KG', 'Gram']}
end
