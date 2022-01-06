class TaskActivity < ApplicationRecord
	belongs_to :restaurant
	#belongs_to :country
	# belongs_to :task_type
	# belongs_to :task_category

	serialize :country_ids, Array


	def countries
		Country.where(id: self.country_ids)
	end
end
