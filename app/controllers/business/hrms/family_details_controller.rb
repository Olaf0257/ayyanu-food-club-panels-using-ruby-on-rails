class Business::Hrms::FamilyDetailsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"
  before_action :find_family, only: [:find_country_based_branch]


  def dashboard
    render layout: "partner_application"
  end

  def index
    @family_details = FamilyDetail.all.where(restaurant_id: params[:restaurant_id]).order("created_at desc")
    render layout: "partner_application"
  end

  def new
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @family_detail = FamilyDetail.new
    # @family.build_family_details
    render layout: "partner_application"
  end

  def create
    family = FamilyDetail.new(family_params)
    if family.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = family.errors.full_messages.first.to_s
    end
    redirect_to business_hrms_family_details_path(restaurant_id: params[:restaurant_id])
  end

  def edit
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @family_detail = FamilyDetail.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @family = FamilyDetail.find_by(id: params[:id])
    if @family.update(family_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_hrms_family_details_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @family.errors.full_messages.join(", ")
    end
  end

  def destroy
    @family = FamilyDetail.find_by(id: params[:id])
    if @family.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_family_details_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @family.errors.full_messages.join(", ")
    end
  end

  def find_country_based_branch
    @task_types = []
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:country_name])
  end

  def reporting_to_list
    branches = Branch.where(id: params[:branches])
    @managers = branches.map{ |branch| branch.managers.where(approval_status: User::APPROVAL_STATUS[:approved]) }
  end

  private

  def family_params
    params.require(:family_detail).permit(:name, :relation, :gender, :profession, :nationality, :address, :notes, :employee_id, :created_by_id, :contact, :country_code, :restaurant_id, :country_ids => [], :location => [])
  end

  def find_family
    @family_detail= FamilyDetail.find_by(id: params[:id])
  end
end
