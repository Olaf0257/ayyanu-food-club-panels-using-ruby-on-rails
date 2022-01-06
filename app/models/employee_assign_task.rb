class EmployeeAssignTask < ApplicationRecord


	def task_list
		TaskList.find_by(id: self.task_list_id)
	end


	def employee
		Employee.find_by(id: self.employee_id)
	end
end
