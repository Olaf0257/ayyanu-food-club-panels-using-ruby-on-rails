class Loan < ApplicationRecord
	DEDUCTED_FROM = [['Salary','salary'],['At end contract','at end contract']]
	STATUS = { 'pending': 'pending', 'approved': 'approved', 'rejected': 'rejected' }

	belongs_to :user
	# belongs_to :department
	# belongs_to :designation
	# before_create :create_account_number
	belongs_to :loan_type
	has_one :loan_revise

	# def create_account_number
	# 	self.account_number = rand(10 ** 10)
	# end
end
