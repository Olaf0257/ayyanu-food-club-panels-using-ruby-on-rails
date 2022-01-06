class Employee < User
  EMPLOYEMENT_TYPE = [["Permanent", 'permanent'], ['Temporary', 'temporary']]
  EMPLOYEMENT_TYPE = [["Permanent",0], ['Temporary',1]]
  GENDER = [["Male", 'Male'], ['Female','female'], ['Others', 'others']]
  STATUS = [["Confirm",'confirm'],['Contract','contract'],['Probation','probation'],['Trainee','trainee']]
  STATUS = [["Confirm",0],['Contract',1],['Probation',2],['Trainee',3]]
  PROBATION_PERIOD = [['Numerical','numerical']]
  GRADE = [['Pan Number','Pan Number']]
  # PAYMENT_MODE = [['Cash','cash'],['Bank Transfer','bank transfer'],['Cheque','cheque'],['Demand Draft','demand draft']]

  has_one :user_detail, :dependent => :destroy, as: :detailable
  has_one :family_detail
  has_many :employee_assign_tasks
  has_one :asset
  accepts_nested_attributes_for :user_detail, reject_if: :all_blank, allow_destroy: true



  def self.get_task_percentage_csv(emp_list)
     CSV.generate do |csv|
      # header = "Task Percentage List"
      # csv << [header]
      second_row = ["Country","Branch","Employee_Name","Department","Designation","Total_Task","Completed_Task", "Percentage"]
      csv << second_row

      emp_list.each do |employee|
        @row = []
        @row << employee&.country&.name
        @row << find_location_name_employee(employee)
        @row << employee.name
        @row << employee.user_detail&.department&.name
        @row << employee.user_detail&.designation&.titleize 
        @row << total_tasks(employee.id) 
        @row << find_assign_tasks(employee.id)
        @row << "#{task_completed_percentage(employee.id)}%"
        csv << @row
      end
    end
  end


  def self.find_assign_tasks(emp_id)
    EmployeeAssignTask.where(employee_id:  emp_id,is_completed: true).count
  end


  def self.total_tasks(emp_id)
    EmployeeAssignTask.where(employee_id:  emp_id).count
  end

  def self.task_completed_percentage(emp_id)
    percent = (EmployeeAssignTask.where(employee_id:  emp_id,is_completed: true).count.to_f/EmployeeAssignTask.where(employee_id:  emp_id).count.to_f).round(2) * 100 

    if percent.nan?
      0 
    else
      percent
    end
  end



  def self.find_location_name_employee(employee)
    if employee.user_detail.department&.name == "Transporter"
      employee.branch_transports.map{|b| b.branch.address}
    elsif employee.user_detail.department&.name == "Manager"
      employee.branch_managers.map{|b| b.branch.address}
    elsif employee.user_detail.department&.name == "Kitchen Manager"
      # employee.kitchen_managers.map{|b| b.branch.id }
      employee.kitchen_managers.map{|b| b.address }
    else
      employee.kitchen_managers.map{|b| b.address }
    end
  end



end