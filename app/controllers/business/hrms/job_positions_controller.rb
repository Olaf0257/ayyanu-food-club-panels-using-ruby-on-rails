class Business::Hrms::JobPositionsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @job_postions = JobPosition.where(restaurant_id: decode_token(params[:restaurant_id])).all.order("created_at desc")
  end

  def new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id])) 
    @job_position = JobPosition.new
  end

  def create
    pdf_url = upload_multipart_image(params[:job_position][:job_description], "job_positions", original_filename=nil)
    @job_position = JobPosition.new(job_position_params.merge(restaurant_id: decode_token(params[:restaurant_id]), name_of_rounds: params[:round_names]&.values, job_description: pdf_url))
    if @job_position.save
      flash[:success] = "Created Successfully!"
      redirect_to  business_hrms_job_positions_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @job_position.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    @job_postions = @restaurant.task_types
    @job_position = JobPosition.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @job_position = JobPosition.find_by(id: params[:id])
    unless params[:job_position][:job_description].blank?
      pdf_url = upload_multipart_image(params[:job_position][:job_description], "job_positions", original_filename=nil) 
      @job_postion_params = job_position_params.merge(name_of_rounds: params[:round_names]&.values, job_description: pdf_url)
    else
      @job_postion_params = job_position_params.merge(name_of_rounds: params[:round_names]&.values)
    end
    if @job_position.update(@job_postion_params)
      flash[:success] = "Updated Successfully!"
      redirect_to  business_hrms_job_positions_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @job_position.errors.full_messages.join(", ")
      render :new
    end
  end

  def destroy
    @job_position = JobPosition.find_by(id: params[:id])
    if @job_position.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to  business_hrms_job_positions_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @job_position.errors.full_messages.join(", ")
      render :new
    end
  end

  def find_country_based_branch
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:country_name])
  end

  def department_designation
    department = Department.find_by_id(params[:id])
    @designations = department.designations
  end

  private

  def job_position_params
    params.require(:job_position).permit(:department_id, :designation_id, :title, :candidate_name, :number_of_rounds, :status, :requirement_responsibility, :expected_employees, :name_of_rounds, :created_by_id, :image, :location => [] , :country_ids => [])
  end
end
