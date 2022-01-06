class UserDetail < ApplicationRecord
	belongs_to :detailable, polymorphic: true
	belongs_to :department

	serialize :country_ids, Array

end
