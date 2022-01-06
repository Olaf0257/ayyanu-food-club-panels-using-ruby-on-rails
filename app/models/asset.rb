class Asset < ApplicationRecord
	belongs_to :asset_category,optional: true
	belongs_to :brand, optional: true
	belongs_to :asset_type, optional: true
	belongs_to :branch, optional: true
	belongs_to :station, optional: true
end
