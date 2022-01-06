class UserPrivilege < ApplicationRecord

	serialize :country_ids, Array
	serialize :designation_ids, Array
	serialize :branch_ids, Array
	serialize :department_ids, Array
	serialize :fc, Array
	serialize :mc, Array
	serialize :hrms, Array
	serialize :pos, Array
	serialize :masters, Array
	serialize :pos_order_tracking, Array
	serialize :pos_other_pages, Array
	serialize :kds, Array
	serialize :task_management, Array
	serialize :training, Array
	serialize :document_scan, Array
	serialize :reports, Array
	serialize :enterprise, Array



	def assign_privileges

		assign_privilegs = {}
		assign_privilegs["FC"] = self.fc if self.fc.present?
		assign_privilegs["MC"] = self.mc if self.mc.present?
		assign_privilegs["HRMS"] = self.hrms if self.hrms.present?
		assign_privilegs["POS"] = self.pos if self.pos.present?
		assign_privilegs["POS ORDER TRACKING"] = self.pos_order_tracking  if self.pos_order_tracking.present?
		assign_privilegs["POS OTHER PAGES"] = self.pos_other_pages  if self.pos_other_pages.present?
		assign_privilegs["MASTERS"] = self.masters  if self.masters.present?
		assign_privilegs["KDS"] = self.kds  if self.kds.present?
		assign_privilegs["TASK MANAGEMENT"] = self.task_management  if self.task_management.present?
		assign_privilegs["TRAINING"] = self.training  if self.training.present?
		assign_privilegs["DOCUMENT_SCAN"] = self.document_scan  if self.document_scan.present?
		assign_privilegs["REPORTS"] = self.reports  if self.reports.present?
		assign_privilegs["ENTERPRISE"] = self.enterprise  if self.enterprise.present?

		assign_privilegs

	end
end

