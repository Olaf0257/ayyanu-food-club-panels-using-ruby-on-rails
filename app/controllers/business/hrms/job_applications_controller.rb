class Business::Hrms::JobApplicationsController < ApplicationController
	before_action :authenticate_business
  layout "partner_application"

  def index
    if (params[:searched_department_id].present? || params[:searched_designation_id].present? || params[:keyword].present?)
      @job_openings = JobOpening.where(status: "pending").search_job_application_list(params[:searched_department_id], params[:searched_designation_id], params[:keyword]).order("created_at desc")
    else
      @job_openings = JobOpening.where(status: "pending").order("created_at desc")
    end
    respond_to do |format|
      format.html
      format.csv { send_data @job_openings.job_application_csv, filename: "job_application_list.csv" }
    end
  end

  def approve_application
    job_opening = JobOpening.find_by_id(params[:id])
    job_opening.update(status: "approved")
    flash[:success] = "Application Approved!"
    redirect_to business_hrms_job_applications_path(restaurant_id: params[:restaurant_id])
  end

  def reject_application
    job_opening = JobOpening.find_by_id(params[:id])
    job_opening.update(status: "rejected", rejected_reason: params[:rejected_reason])
    flash[:success] = "Application Rejected!"
    redirect_to business_hrms_job_applications_path(restaurant_id: params[:restaurant_id])
  end

  def hold_application
    job_opening = JobOpening.find_by_id(params[:id])
    job_opening.update(status: "holded")
    flash[:success] = "Application holded!"
    redirect_to business_hrms_job_applications_path(restaurant_id: params[:restaurant_id])
  end

  def unhold_application
    job_opening = JobOpening.find_by_id(params[:id])
    job_opening.update(status: "pending")
    flash[:success] = "Application unholded!"
    redirect_to business_hrms_holded_application_path(restaurant_id: params[:restaurant_id])
  end

  def approved_application
    if (params[:searched_department_id].present? || params[:searched_designation_id].present? || params[:keyword].present?)
      @job_openings = JobOpening.where(status: "approved").search_job_application_list(params[:searched_department_id], params[:searched_designation_id], params[:keyword]).order("updated_at desc")
    else
      @job_openings = JobOpening.where(status: "approved").order("updated_at desc")
    end
    respond_to do |format|
      format.html
      format.csv { send_data @job_openings.job_application_csv, filename: "job_application_list.csv" }
    end
  end

  def resume_list
    @resumes = JobOpening.all.order("created_at desc")
  end

  def rejected_application
    if (params[:searched_department_id].present? || params[:searched_designation_id].present? || params[:keyword].present?)
      @job_openings = JobOpening.where(status: "rejected").search_job_application_list(params[:searched_department_id], params[:searched_designation_id], params[:keyword]).order("updated_at desc")
    else
      @job_openings = JobOpening.where(status: "rejected").order("updated_at desc")
    end
    respond_to do |format|
      format.html
      format.csv { send_data @job_openings.job_application_csv, filename: "job_application_list.csv" }
    end
  end

  def holded_application
    if (params[:searched_department_id].present? || params[:searched_designation_id].present? || params[:keyword].present?)
      @job_openings = JobOpening.where(status: "holded").search_job_application_list(params[:searched_department_id], params[:searched_designation_id], params[:keyword]).order("updated_at desc")
    else
      @job_openings = JobOpening.where(status: "holded").order("updated_at desc")
    end
    respond_to do |format|
      format.html
      format.csv { send_data @job_openings.job_application_csv, filename: "job_application_list.csv" }
    end
  end
end
