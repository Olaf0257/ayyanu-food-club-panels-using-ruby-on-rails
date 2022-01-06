class FamilyDetail < ApplicationRecord
	belongs_to :employee
	serialize :country_ids, Array
	serialize :location, Array
end
