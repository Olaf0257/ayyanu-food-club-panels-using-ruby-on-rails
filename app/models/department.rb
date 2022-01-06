class Department < ApplicationRecord
	belongs_to :restaurant
	has_many :designations, dependent: :destroy
end
