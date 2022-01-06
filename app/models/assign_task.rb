class AssignTask < ApplicationRecord

	after_destroy :destroy_employee_assign_tasks
	after_update :update_employee_assign_task

	def destroy_employee_assign_tasks
		emp_tasks = EmployeeAssignTask.where(assign_task_id: self.id)
		emp_tasks.destroy_all
	end




	def update_employee_assign_task
		ids = []
		self.employee_ids.split(",").each do |employee_id|
	        self.task_list_ids.split(",").each do |task_id|
	        	emp_task = EmployeeAssignTask.find_by(assign_task_id: self.id,employee_id: employee_id,task_list_id: task_id)
	        	if emp_task.present?
	        		ids << emp_task.id
	        		emp_task.update(assign_date_time: self.assign_date_time)
	        	else
	        		emp_task = EmployeeAssignTask.create(assign_task_id: self.id,employee_id: employee_id,task_list_id: task_id,assign_date_time: self.assign_date_time)
	        		ids << emp_task.id
	        	end
	        end
    	end
    	EmployeeAssignTask.where(assign_task_id: self.id).where.not(id: ids).destroy_all
	end


end

