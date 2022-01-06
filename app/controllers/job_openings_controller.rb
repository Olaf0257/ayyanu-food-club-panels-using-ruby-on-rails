class JobOpeningsController < ApplicationController
	def create
    @job_opening = JobOpening.new(job_opening_params)
    if @job_opening.save
			resume_file = upload_multipart_image(job_opening_params[:resume_file], "job_openings", original_filename=nil)
      @job_opening.update(resume_file: resume_file)
      flash[:success] = "Application Submitted Successfully!"
    else
      flash[:error] = @job_opening.errors.full_messages.join(", ")
    end
    redirect_to job_opening_path(job_opening_params[:job_position_id])
	end

	def show
    @job_opening = JobOpening.new
    @job_position = JobPosition.find(params[:id])

    @selected_country_id = params[:country_id].present? ? decode_token(params[:country_id]) : (session[:country_id].presence || 15)
    session[:country_id] = @selected_country_id
    @countries = Country.where(id: Restaurant.joins(:branches).where(is_signed: true, branches: { is_approved: true }).pluck(:country_id).uniq).where.not(id: @selected_country_id)
    @country_name = Country.find(@selected_country_id).name
    @categories = Category.where.not(icon: nil, icon: "").order_by_title
    @categories = @categories.where.not(title: "Party") if Point.sellable_restaurant_wise_points(@selected_country_id).empty?
    @areas = CoverageArea.active_areas.where(country_id: @selected_country_id)
    @restaurants = Restaurant.joins(:branches).where(country_id: @selected_country_id, is_signed: true, branches: { is_approved: true }).where.not(title: "").distinct.order(:title).first(7)
	end

  private
	def job_opening_params
    params.require(:job_opening).permit(:first_name, :last_name, :email, :phone_number, :total_experience, :resume_file, :country_id, :job_position_id, :country_code)
  end
end
