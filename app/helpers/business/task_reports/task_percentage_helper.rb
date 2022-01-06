module Business::TaskReports::TaskPercentageHelper


	def find_assign_tasks(emp_id)
		EmployeeAssignTask.where(employee_id:  emp_id,is_completed: true).count
	end


	def total_tasks(emp_id)
		EmployeeAssignTask.where(employee_id:  emp_id).count
	end

	def task_completed_percentage(emp_id)
		percent = (EmployeeAssignTask.where(employee_id:  emp_id,is_completed: true).count.to_f/EmployeeAssignTask.where(employee_id:  emp_id).count.to_f).round(2) * 100 

		if percent.nan?
			0 
		else
			percent
		end
	end

end