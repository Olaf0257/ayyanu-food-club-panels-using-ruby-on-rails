class LoanSettlement < ApplicationRecord
	belongs_to :user
	belongs_to :loan
end
