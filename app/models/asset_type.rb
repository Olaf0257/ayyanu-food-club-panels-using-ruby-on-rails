class AssetType < ApplicationRecord
  has_many :assets
  has_many :asset_categories, class_name: "AssetCategory"
  belongs_to :created_by, class_name: "User"
end
