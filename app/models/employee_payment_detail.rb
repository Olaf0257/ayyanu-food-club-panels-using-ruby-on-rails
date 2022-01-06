class EmployeePaymentDetail < ApplicationRecord
	belongs_to :user
	belongs_to :bank
end
