class TaskList < ApplicationRecord
	belongs_to :restaurant
	#belongs_to :country
	belongs_to :task_type
	belongs_to :task_category
	belongs_to :task_sub_category
	belongs_to :task_activity
	serialize :country_ids, Array
	serialize :location, Array
	after_destroy :destroy_assign_tasks

	def countries
		Country.where(id: self.country_ids)
	end

	def destroy_assign_tasks
	  	emp_task = EmployeeAssignTask.where(task_list_id: self.id)
	  	assign_tasks = AssignTask.where(id: emp_task.pluck(:assign_task_id))
	  	assign_tasks.each do |assgn_task|
	    	task_ids = assgn_task.task_list_ids.split(",")
		    if task_ids.include?(self.id.to_s)
		        task_ids.delete(self.id.to_s)
		        if task_ids.join(",") == ""
		          assgn_task.destroy
		        else
		          assgn_task.update(task_list_ids: task_ids.join(","))
		        end
		    end
	  	end
	  	emp_task.destroy_all
	end
end
