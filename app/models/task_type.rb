class TaskType < ApplicationRecord
	belongs_to :restaurant
	#belongs_to :country
	has_many :task_categories
	serialize :country_ids, Array


	def countries
		Country.where(id: self.country_ids)
	end
end
