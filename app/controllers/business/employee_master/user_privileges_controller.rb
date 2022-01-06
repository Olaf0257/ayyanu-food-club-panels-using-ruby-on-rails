class Business::EmployeeMaster::UserPrivilegesController < ApplicationController
	before_action :authenticate_business
	layout "partner_application"

	def index
		@restaurant_id =params[:restaurant_id]
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
		@privileges = UserPrivilege.all.order("created_at desc")
	end


	def new
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
		@privilege = UserPrivilege.new
	end



	def create
		@privilege = UserPrivilege.new(user_privileges_params)
	    if @privilege.save
	      flash[:success] = "Privilege Created Successfully!"
	    else
	      flash[:error] = @privilege.errors.full_messages.join(", ")
	    end
	    redirect_to business_employee_master_restaurant_user_privileges_path(restaurant_id: params[:user_privilege][:restaurant_id])
	end



	def edit
		@restaurant_id = params[:restaurant_id]
	    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
	    @privilege = UserPrivilege.find_by(id: params[:id])
	    render layout: "partner_application"
	end


	def update 
		@restaurant_id =params[:restaurant_id]
    	@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    	@privilege = UserPrivilege.find_by(id: params[:id])
    	if @privilege.update(user_privileges_params)
      		flash[:success] = "Privilege Updated Successfully!"
      		redirect_to business_employee_master_restaurant_user_privileges_path(restaurant_id: @restaurant_id)
    	else
      		flash[:error] = @privilege.errors.full_messages.join(", ")
    	end
	end


	def find_country_based_branch
		@task_types = []
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
		@branches = @restaurant.branches.where(country: params[:country_name])
	end

	def find_designation_based_department
		departments = Department.where(name: params[:id])
		privilege_designation_ids =  UserPrivilege.pluck(:designation_ids).flatten
		@designations = Designation.where(department_id: departments.pluck(:id)).where.not(id: privilege_designation_ids)
	end



	def destroy
		@privilege = UserPrivilege.find_by(id: params[:id])
	    if @privilege.destroy
	      flash[:success] = "Privilege Deleted Successfully!"
	      redirect_to  business_employee_master_restaurant_user_privileges_path(restaurant_id: params[:restaurant_id])
	    else
	      flash[:error] = @privilege.errors.full_messages.join(", ")
	    end
	end


	private
	  def user_privileges_params
	  
	    params[:user_privilege][:hrms] = params[:hrms].values  rescue []
	   	params[:user_privilege][:fc] = params[:fc].values rescue []
	    params[:user_privilege][:pos] = params[:pos].values rescue []
	    params[:user_privilege][:pos_order_tracking] = params[:pos_order_tracking].values rescue []
	    params[:user_privilege][:pos_other_pages] = params[:pos_other_pages].values rescue []
	    params[:user_privilege][:mc] = params[:mc].values rescue []
	    params[:user_privilege][:kds] = params[:kds].values  rescue []
	    params[:user_privilege][:masters] = params[:masters].values rescue []
	    params[:user_privilege][:task_management] = params[:task_management].values rescue []
	    params[:user_privilege][:document_scan] = params[:document_scan].values rescue []
	    params[:user_privilege][:reports] = params[:reports].values  rescue []
	    params[:user_privilege][:enterprise] = params[:enterprise].values rescue []
	    params[:user_privilege][:training] = params[:training].values  rescue []
	 
	    params.require(:user_privilege).permit(:created_by_id, country_ids: [], branch_ids: [], department_ids: [], designation_ids: [], fc: [], hrms: [], mc: [], pos: [], pos_order_tracking: [], task_management: [], masters: [], kds: [], pos_other_pages: [] ,enterprise: [] ,reports: [] , document_scan: [],training: [] )
	  end


end