class Budget < ApplicationRecord
  belongs_to :branch

  def self.crete_new_budget(branch, amount, start_date, end_date)
    create(amount: amount, start_date: start_date, end_date: end_date, branch_id: branch.id)
  end
end
