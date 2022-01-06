class AssetCategory < ApplicationRecord
	has_many :assets
	belongs_to :asset_type,optional: true
	belongs_to :created_by, class_name: "User"
end