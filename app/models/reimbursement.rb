class Reimbursement < ApplicationRecord
	belongs_to :user
	belongs_to :reimbursement_type
	STATUS = { 'pending': 'pending', 'approved': 'approved', 'rejected': 'rejected' }
end
