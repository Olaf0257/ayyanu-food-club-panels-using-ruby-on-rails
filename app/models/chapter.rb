class Chapter < ApplicationRecord
	belongs_to :manual, optional: true
	# belongs_to :user, optional: true
	has_many :chapter_employees,class_name: "ChapterEmpolyee"
	has_many :users, through: :chapter_employees
	belongs_to :created_by, class_name: "User"
end
