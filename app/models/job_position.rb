class JobPosition < ApplicationRecord
	belongs_to :designation
	belongs_to :department
	belongs_to :restaurant
	#belongs_to :country
	serialize :country_ids, Array


	def countries
		Country.where(id: self.country_ids)
	end
end
