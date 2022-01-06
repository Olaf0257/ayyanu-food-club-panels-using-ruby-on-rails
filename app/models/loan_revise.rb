class LoanRevise < ApplicationRecord
	belongs_to :loan
	before_save :update_loan_amount

	def update_loan_amount
		if self.status == "approved"
			loan = self.loan
			new_amount = self.topup_amount + loan.amount
			loan.update(amount: new_amount, original_amount: loan.amount)
		end
	end
end