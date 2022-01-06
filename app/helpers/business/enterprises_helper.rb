module Business::EnterprisesHelper
	def find_location_ids_user(employee)
    if employee.user_detail.department&.name == "Transporter"
      employee.branch_transports&.uniq
    elsif employee.user_detail.department&.name == "Manager"
      employee.branch_managers&.uniq
    elsif employee.user_detail.department&.name == "Kitchen Manager"
      # employee.kitchen_managers.map{|b| b.branch.id }
      employee.kitchen_managers&.uniq
    else
      employee.kitchen_managers&.uniq
    end
  end
end
