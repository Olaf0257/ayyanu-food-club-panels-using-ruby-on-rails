class AssignAsset < ApplicationRecord
	STATUS = [['Lost','lost'],['Returned','returned'],['Damaged','damaged']]
	belongs_to :user,optional: true
	belongs_to :asset_category, optional: true
	belongs_to :asset, optional: true
	belongs_to :asset_type, optional: true
end
