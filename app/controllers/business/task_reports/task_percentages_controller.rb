class Business::TaskReports::TaskPercentagesController < ApplicationController
	before_action :authenticate_business
  	layout "partner_application"

  	def dashboard
    	render layout: "partner_application"
  	end


  	def index
  		user_ids = find_employees(params)
      task_list_ids = TaskList.where("time_to <= ? or time_from >= ? ", Date.today ,Date.today ).pluck(:id)
      user_ids = EmployeeAssignTask.where(employee_id: user_ids.flatten,task_list_id: task_list_ids).pluck(:employee_id)
  		@countries = Country.pluck(:name, :id).sort
  		@branches = Branch.where(id: 0).pluck(:address, :id)
  		@designations = Designation.where(id: 0).pluck(:name, :name).sort
  		@departments = Department.pluck(:name, :id).sort
    	@employees =  User.where(id: user_ids, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    	
   		@employees = @employees.where(country_id: params[:searched_country_id]) if params[:searched_country_id].present?
      @employees = @employees.where(id: params[:searched_emp_id]) if params[:searched_emp_id].present?
      @employees = @employees.joins(:user_detail).where(user_details: {department_id: params[:searched_department_id]}) if params[:searched_department_id].present?
      if params[:searched_designation_id].present?
        designation = Designation.find_by(id: params[:searched_designation_id])
        @employees = @employees.joins(:user_detail).where(user_details: {designation: designation.name}) 
      end
      tasklists_ids = TaskList.where("time_to <= ? or time_from >= ? ", params[:start_date] ,params[:end_date] ).pluck(:id) if params[:start_date].present? &&  params[:end_date].present?      
      if tasklists_ids.present?
        emp_task_ids = EmployeeAssignTask.where(task_list_id:  tasklists_ids).pluck(:employee_id)
        @employees = @employees.where(id: emp_task_ids.flatten) 
      end
      params[:start_date] = Date.today unless params[:start_date].present?
      params[:end_date] = Date.today unless params[:end_date].present?

      if params[:searched_branch_id].present?
        @employees = search_branch_employee(@employees,params[:searched_branch_id]) 
        @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      end

      respond_to do |format|
        format.html do
          @employees = @employees.paginate(page: params[:page], per_page: 20)
          render layout: "partner_application"
        end
        format.csv { send_data Employee.get_task_percentage_csv(@employees), filename: "Employee_Task_Percentage.csv" }
      end

  	end


  	def assigned_tasks
      @task_lists =  EmployeeAssignTask.where(employee_id:  params[:task_percentage_id]).order("created_at desc")
  	end


    def  find_country_based_branch
      @task_types = []
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @branches = @restaurant.branches.where(country: params[:country_name])
    end

    def find_designation_based_department
      departments = Department.where(id: params[:id])
      @designations = Designation.where(department_id: departments.ids)
    end


    def find_employee_based_designation
      designation = Designation.where(id: params[:id])
      @employees = User.joins(user_detail: {department: :designations}).where(designations: {id: designation.ids})
    end


    def search_branch_employee(employees,branch_id)
      branch_employees = []
      employees.each do |employee|
        if employee.user_detail.department&.name == "Transporter"
          employee.branch_transports.each{|b| branch_employees << employee if b.branch.id  == branch_id.to_i }
        elsif employee.user_detail.department&.name == "Manager"
          employee.branch_managers.each{|b| branch_employees << employee if b.branch.id  == branch_id.to_i}
        elsif employee.user_detail.department&.name == "Kitchen Manager"
          # employee.kitchen_managers.each{|b| b.branch.id }
          employee.kitchen_managers.each{|b| branch_employees << employee if b.id == branch_id.to_i }
        else
          employee.kitchen_managers.each{|b| branch_employees << employee if b.id  == branch_id.to_i }
        end
      end

      branch_employees= branch_employees.uniq
    end

end