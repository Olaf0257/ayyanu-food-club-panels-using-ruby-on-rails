module Business::Hrms::EmployeesHelper

  def created_by(user_detail)
    user = User.find_by_id(user_detail.created_by_id)
    unless user.blank?
      if user.auths.first.role == "business" 
        user&.name
      elsif user.auths.first.role == "manager" 
        user.branch_managers.first.branch.restaurant.title
      elsif user.auths.first.role == "kitchen_manager" || user.auths.first.role == "delivery_company" || user.influencer 
        user&.name 
      end 
    end
  end

  def find_locations(employee)
    if employee.user_detail.blank?
      branches = employee.branch_transports.map{|b| b.branch.address }.join(",") || employee.branch_managers.map{|b| b.branch.address }.join(",") || employee.kitchen_managers.map{|b| b.branch.address }.join(",")
    elsif employee.user_detail.department&.name == "Transporter"
      employee.branch_transports.map{|b| b.branch.address }.last
    elsif employee.user_detail.department&.name == "Manager"
      employee.branch_managers.map{|b| b.branch.address }.uniq.join(",")
    elsif employee.user_detail.department&.name == "Kitchen Manager"
      # employee.kitchen_managers.map{|b| b.branch.id }
      # employee.kitchen_managers.map{|b| b.address }.join(",")
      employee.kitchen_managers.map(&:address).last
    else
      employee.kitchen_managers.map(&:address).last
    end
  end


  def find_location_employee(employee,name_val=false)
      ids = employee.user_detail.location.split(",") rescue []
      if name_val.present?
         Branch.where(id: ids).pluck(:address).join(",")
      else
        Branch.where(id: ids).pluck(:id)
      end
  end

  def find_location_ids(employee)
    if employee.user_detail.department&.name == "Transporter"
      employee.branch_transports.map{|b| b.branch.id }
    elsif employee.user_detail.department&.name == "Manager"
      employee.branch_managers.map{|b| b.branch.id }
    elsif employee.user_detail.department&.name == "Kitchen Manager"
      # employee.kitchen_managers.map{|b| b.branch.id }
      employee.kitchen_managers.map{|b| b.id }
    else
      employee.kitchen_managers.map{|b| b.id }
    end
  end

  def find_location_ids_employee(employee)
    if employee.user_detail.department&.name == "Transporter"
      employee.branch_transports.map{|b| b.branch.id }
    elsif employee.user_detail.department&.name == "Manager"
      employee.branch_managers.map{|b| b.branch.id }
    elsif employee.user_detail.department&.name == "Kitchen Manager"
      # employee.kitchen_managers.map{|b| b.branch.id }
      employee.kitchen_managers.map{|b| b.id }
    else
      employee.kitchen_managers.map{|b| b.id }
    end
  end


  def find_location_name_employee(employee)
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

  def find_designations(designations)
    designation_arry = []
    designations&.each do |designation|
      designation_arry << [designation.name, designation.name.downcase]
    end
    designation_arry
  end

  def find_department_designation(id)
    department = Department.find_by_id(id)
    if department.blank?
      []
    else
      department.designations
    end
  end

  def reporting_to_list(id)
    branches = Branch.where(id: id)
    branches.map{ |branch| branch.managers.all }
  end

  def find_locations_based_country(employee, restaurant_id)
    restaurant = get_restaurant_data(decode_token(restaurant_id))
    restaurant.branches.where(country: Country.where(id: employee.user_detail.country_ids)&.map(&:name))
  end
end