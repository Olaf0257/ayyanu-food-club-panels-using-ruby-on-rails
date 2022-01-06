class Bank < ApplicationRecord
	belongs_to :updated_by, class_name: "User"
	belongs_to :country
	belongs_to :area, class_name: "CoverageArea"
	def account_details
		"Account no - #{account_number}, IBAN - #{iban}"
	end
	# def address
	# 	[block, road_no, building, floor, additional_direction, phone].join(' ')
	# end
end
