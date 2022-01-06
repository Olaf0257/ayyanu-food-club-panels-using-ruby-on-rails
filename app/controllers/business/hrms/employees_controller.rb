class Business::Hrms::EmployeesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"


  def dashboard
    render layout: "partner_application"
  end

  def index
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    # .paginate(page: params[:page], per_page: 10)

    render layout: "partner_application"
  end

  def show
    @employee = User.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def new
    @employee = User.new
    @employee.build_user_detail
    @employee.build_employee_payment_detail
    render layout: "partner_application"
  end

  def create
    restaurant = params[:restaurant_id]
    if employee_params[:user_detail_attributes][:department] == "manager"
      branch = Branch.where(id: params[:user][:user_detail_attributes][:location])
    else
      branch = Branch.where(id: params[:user][:user_detail_attributes][:location])
    end
    user = employee_params[:user_detail_attributes][:department] == "transporter" ? get_user_cpr_number(employee_params[:cpr_number]) : user_email(employee_params[:email])
    if ((employee_params[:user_detail_attributes][:department] == "transporter") && employee_params[:cpr_number].present? && params[:password].present?) || ((employee_params[:user_detail_attributes][:department] == "manager") && employee_params[:email].present? && params[:password].present?) || ((employee_params[:user_detail_attributes][:department].present?) && employee_params[:email].present? && params[:password].present?)
      designation = employee_params[:user_detail_attributes][:department] == "kitchen manager" ? 'kitchen_manager' : employee_params[:user_detail_attributes][:department]

      if !user && branch
        if employee_params[:user_detail_attributes][:department] == "manager"
          user = create_employee(params[:user][:user_detail_attributes][:location], employee_params[:name], employee_params[:user_detail_attributes][:department] == "transporter" ? employee_params[:cpr_number] + "@gmail.com" : employee_params[:email], designation, employee_params[:contact], params[:country_code], params[:password], params[:image], employee_params[:cpr_number], employee_params[:user_detail_attributes][:vehicle_type],employee_params[:dob],employee_params[:cpr_number_expiry], employee_params[:gender],employee_params[:status], @employee)

        else
          if employee_params[:user_detail_attributes][:department] == "transporter"
            branch =  Branch.where(id: params[:user][:user_detail_attributes][:location])
          else
            branch = params[:user][:user_detail_attributes][:location]
          end
          user = create_employee(branch, employee_params[:name], employee_params[:user_detail_attributes][:department] == "transporter" ? employee_params[:cpr_number] + "@gmail.com" : employee_params[:email], designation, employee_params[:contact], params[:country_code], params[:password], params[:image], employee_params[:cpr_number],  employee_params[:user_detail_attributes][:vehicle_type],employee_params[:dob],employee_params[:cpr_number_expiry], employee_params[:gender],employee_params[:status], @employee)
        end
        UserDetail.create!(employee_params[:user_detail_attributes].except(:department).merge(user_id: user.id, detailable_type: User, detailable_id: user.id))
        EmployeePaymentDetail.create(employee_params[:employee_payment_detail_attributes].merge(user_id: user.id))
        flash[:success] = "Created Successfully!"
      else
        flash[:error] = (employee_params[:user_detail_attributes][:department] == "transporter" ? "Cpr Number already exists " : "Email already exists").to_s
      end
    else
      flash[:error] = "Required parameter is missing!!"
    end
    redirect_to business_hrms_employees_path(restaurant_id: params[:restaurant_id])
  end

  def edit
    @employee = User.find_by(id: params[:id])
    @employee.build_user_detail if @employee.user_detail.blank?
    @employee.build_employee_payment_detail if @employee.employee_payment_detail.blank?
    render layout: "partner_application"
  end

  def find_country_based_branch
    @task_types = []
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:country_name])
  end

  def update
    @employee = User.find_by(id: params[:id])
    approval_status = @employee.approval_status
    restaurant = params[:restaurant_id]
    designation = employee_params[:user_detail_attributes][:department] == "kitchen manager" ? 'kitchen_manager' : employee_params[:user_detail_attributes][:department]

    if employee_params[:user_detail_attributes][:department] == "transporter"
      branch = Branch.find_by_id(params[:user][:user_detail_attributes][:location])
    elsif employee_params[:user_detail_attributes][:department] == "manager"
      branch = params[:user][:user_detail_attributes][:location]
    else
      branch = [params[:user][:user_detail_attributes][:location]]
    end

    user = update_employee_with_details(branch, employee_params[:name], employee_params[:user_detail_attributes][:department] == "transporter" ? employee_params[:cpr_number] + "@gmail.com" : employee_params[:email], designation, employee_params[:contact], params[:country_code], params[:password], params[:image], employee_params[:cpr_number], employee_params[:vehicle_type],employee_params[:dob],employee_params[:cpr_number_expiry],employee_params[:gender],employee_params[:status], @employee)
    if user
      user.build_user_detail if user.user_detail.nil?
      user.update(approval_status: User::APPROVAL_STATUS[:pending])
      user.user_detail.update(employee_params[:user_detail_attributes].except(:department))
      user.user_detail.update_attribute(:location,params["user"]["user_detail_attributes"]["location"])
      user.build_employee_payment_detail if user.employee_payment_detail.nil?
      user.employee_payment_detail.update(employee_params[:employee_payment_detail_attributes])

      flash[:success] = "Updated Successfully!"
      if approval_status == "rejected"
        redirect_to rejected_employee_business_hrms_employees_path(restaurant_id: params[:restaurant_id])
      else
        redirect_to business_hrms_employees_path(restaurant_id: params[:restaurant_id])
      end
    else
      flash[:error] = @employee.errors.full_messages.join(", ")
    end
  end

  # def delete_previous_locations
  #   @employee.branch_transports.delete_all
  #   @employee.branch_managers.delete_all
  #   @employee.kitchen_managers.delete_all
  # end

  def destroy
    @employee = User.find_by(id: params[:id])
    if @employee.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_employees_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @employee.errors.full_messages.join(", ")
    end
  end

  def reporting_to_list
    @employee = Employee.find_by(email: params[:email])
    branches = Branch.where(id: params[:branches])
    @managers = branches.map{ |branch| branch.managers.where(approval_status: User::APPROVAL_STATUS[:approved]) }
  end

  def department_designation
    department = Department.find_by_id(params[:id])
    @designations = department.designations
  end

  def review_employee
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:pending]).order("updated_at desc")
    # .paginate(page: params[:page], per_page: 10)

    render layout: "partner_application"
  end

  def approve_employee
    user = User.find_by_id(params[:id])
    user.update(approval_status: User::APPROVAL_STATUS[:approved])
    flash[:success] = "Employee Approved!"
    redirect_to review_employee_business_hrms_employees_path(restaurant_id: params[:restaurant_id])
  end

  def reject_employee
    user = User.find_by_id(params[:user_id])
    user.update(approval_status: User::APPROVAL_STATUS[:rejected], rejected_reason: params[:rejected_reason])
    flash[:success] = "Employee Rejected!"
    redirect_to review_employee_business_hrms_employees_path(restaurant_id: params[:restaurant_id])
  end

  def rejected_employee
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:rejected]).order("created_at desc")
  end

  def upload_passport
    passport_attributes = {}
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    response = imagekitio.upload_file(
      file = params[:user][:image], # required
      file_name = params[:user][:image].original_filename,  # required
      options= {response_fields: 'isPrivateFile, tags', tags: %w[abc def], use_unique_file_name: true,}
    )

    passport_attributes["name"] = params[:name]
    passport_attributes["dob"] = params[:dob]
    passport_attributes["gender"] = params[:gender]
    passport_attributes["passport_number"] = params[:passport_number]
    passport_attributes["passport_expiry"] = params[:passport_expiry]
    passport_attributes["father_name"] = params[:father_name]
    passport_attributes["cpr_number"] = params[:cpr_number]
    passport_attributes["cpr_expiry"] = params[:cpr_expiry]
    passport_attributes["nationality"] = params[:nationality]

    if request.referer.include?("/edit?restaurant_id")
      redirect_to(request.referer + "&image_url=#{response[:response]["url"]}") + "&passport_attributes=#{passport_attributes}"
    else
      redirect_to new_business_hrms_employee_path(restaurant_id: params[:restaurant_id], image_url: response[:response]["url"], passport_attributes: passport_attributes)
    end
  end

  def auto_populate_info
    @passport_attributes = {}
    result = OCRSpaceService.upload(params[:image_url])
    ocr_result = JSON result
    ocr_result = ocr_result["ParsedResults"][0]["ParsedText"].split("\r\n")
    if ocr_result.include?("Card Expiry Date")
      find_cpr_expiry(ocr_result)
      @passport_attributes["name"] = params[:name]
      @passport_attributes["dob"] = params[:dob]
      @passport_attributes["gender"] = params[:gender]
      @passport_attributes["passport_number"] = params[:passport_number]
      @passport_attributes["passport_expiry"] = params[:passport_expiry]
      @passport_attributes["father_name"] = params[:father_name]
      @passport_attributes["nationality"] = params[:nationality]
      @passport_attributes["cpr_number"] = params[:cpr_number]
    elsif ocr_result.length > 5
      find_passport_name(ocr_result)
      find_passport_dob(ocr_result)
      find_passport_gender(ocr_result)
      find_passport_passport_number(ocr_result)
      find_passport_expiry(ocr_result)
      find_passport_father_name(ocr_result)
      find_passport_nationality(ocr_result)
      # session[:passport_attributes] = @passport_attributes
      @passport_attributes["cpr_number"] = params[:cpr_number]
      @passport_attributes["cpr_expiry"] = params[:cpr_expiry]
      # @passport_attributes
    else
      @passport_attributes = session[:passport_attributes] || {}
      find_cpr_number(ocr_result)
      # session[:passport_attributes] = @passport_attributes
      @passport_attributes["name"] = params[:name]
      @passport_attributes["dob"] = params[:dob]
      @passport_attributes["gender"] = params[:gender]
      @passport_attributes["passport_number"] = params[:passport_number]
      @passport_attributes["passport_expiry"] = params[:passport_expiry]
      @passport_attributes["father_name"] = params[:father_name]
      @passport_attributes["nationality"] = params[:nationality]
      @passport_attributes["cpr_expiry"] = params[:cpr_expiry]
      # @passport_attributes["cpr_number"] = params[:cpr_number]
    end
  end

  def find_passport_name(ocr_result)
    @passport_attributes["name"] = ocr_result[5] rescue nil
  end

  def find_passport_dob(ocr_result)
    @passport_attributes["dob"] = ocr_result[13] rescue nil
  end

  def find_passport_gender(ocr_result)
    @passport_attributes["gender"] = nil
  end

  def find_passport_passport_number(ocr_result)
    @passport_attributes["passport_number"] = ocr_result[21] rescue nil
  end

  def find_passport_expiry(ocr_result)
    @passport_attributes["passport_expiry"] = ocr_result[14] rescue nil
  end

  def find_passport_father_name(ocr_result)
    @passport_attributes["father_name"] = ocr_result[17].downcase.gsub("1","i") rescue nil
  end

  def find_passport_nationality(ocr_result)
    @passport_attributes["nationality"] = ocr_result[3] rescue nil
  end

  def find_cpr_number(ocr_result)
    @passport_attributes["cpr_number"] = ocr_result[2] rescue nil
  end

  def find_cpr_expiry(ocr_result)
    @passport_attributes["cpr_expiry"] = ocr_result[ocr_result.length - 3] rescue nil
  end

  private

  def employee_params
    params[:user][:user_detail_attributes][:department] = Department.find_by_id(params[:user][:user_detail_attributes][:department_id])&.name&.downcase
    unless params[:user][:user_detail_attributes][:location].class == String
      params[:user][:user_detail_attributes][:location]&.reject!(&:empty?)
      params[:user][:user_detail_attributes][:location] = params[:user][:user_detail_attributes][:location].join(",") 
    end

    params.require(:user).permit(:name,:email,:contact,:dob, :cpr_number, :password, :vehicle_type, :gender, :cpr_number_expiry, :country_code, :status, user_detail_attributes: [:department, :total_experience, :employement_type,:reporting_to, :probation_period, :confirmation_date, :emergency_contact_name, :emergency_contact_number, :father_name, :spouse_name, :designation, :department_id, :location, :grade, :include_pf, :pf_number, :uan_number, :pf_excess_contribution, :include_esi, :esi_number, :include_lwf, :payment_mode, :bank_name, :account_type, :account_number, :ifsc, :branch_name, :dd_payable_at, :total_experience, :last_epmloyer, :contract_expiry_date, :number_of_annual_leaves, :vacation_date, :deployment_branch, :cpr_identity_number, :cpr_identity_expiry, :vehicle_type, :current_address, :passport_number, :passport_expiry, :vaccine_date, :booster_dose_date, :visa_number, :visa_expiry, :notice_period_days, :employee_weekdays, :created_by_id, :pan_number, :status, :nationality, :signature, :guarantor,country_ids: []], employee_payment_detail_attributes: [:bank_id, :branch, :account_type, :account_number, :ifsc_code, :branch_name, :dd_payable_at])
  end

end
