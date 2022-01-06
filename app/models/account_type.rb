class AccountType < ApplicationRecord
	belongs_to :updated_by, class_name: "User"
	belongs_to :restaurant
	has_many :account_categories

	def self.search(condition)
     where("name like ?", "#{condition}%")
  end
end
