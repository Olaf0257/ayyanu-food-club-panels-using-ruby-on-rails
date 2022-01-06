module Business::Hrms::LoanRevisesHelper

  def find_loans(restaurant_id)
  	Loan.where(status: Loan::STATUS[:approved], restaurant_id: restaurant_id)
  end
end