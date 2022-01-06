class Manual < ApplicationRecord
	belongs_to :created_by, class_name: "User"
	belongs_to :manual_category
end
