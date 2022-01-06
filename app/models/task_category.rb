class TaskCategory < ApplicationRecord
	belongs_to :restaurant
	#belongs_to :country
	belongs_to :task_type
	has_many :task_activities
	# belongs_to :area, class_name: "CoverageArea"
	serialize :country_ids, Array
	has_many :task_sub_categories


	def countries
		Country.where(id: self.country_ids)
	end
end
