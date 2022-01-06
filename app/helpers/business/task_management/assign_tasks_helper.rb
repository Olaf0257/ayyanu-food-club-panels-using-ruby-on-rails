module Business::TaskManagement::AssignTasksHelper
	def find_assign_task_country(assign_task)
    countries = Country.where(id: assign_task.country_ids.split(",")) unless assign_task.country_ids.blank?
    countries.map(&:name).join(",") unless countries.blank?
	end

	def find_assign_task_branch(assign_task)
    branches = Branch.where(id: assign_task.branch_ids.split(",")) unless assign_task.branch_ids.blank?
    branches.map(&:address).join(",") unless branches.blank?
	end

	def find_assign_task_department(assign_task)
		departments = Department.where(id: assign_task.department_ids.split(",")) unless assign_task.department_ids.blank?
    departments.map(&:name).join(",") unless departments.blank?
	end

	def find_assign_task_designation(assign_task)
    designations = Designation.where(id: assign_task.designation_ids.split(",")) unless assign_task.designation_ids.blank?
    designations.map(&:name).join(",") unless designations.blank?
	end

	def find_assign_task_employee(assign_task)
    employees = User.where(id: assign_task.employee_ids.split(",")) unless assign_task.employee_ids.blank?
    employees.map(&:name).join(",") unless employees.blank?
	end

	def find_assign_task_task_list(assign_task)
    tasklists = TaskList.where(id: assign_task.task_list_ids.split(",")) unless assign_task.task_list_ids.blank?
    tasklists.map(&:name).join(",") unless tasklists.blank?
	end
end
