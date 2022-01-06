class Business::TasksListController < ApplicationController
  before_action :authenticate_business

  def index
    @user
    respond_to do |format|
      format.html { render layout: "partner_application" }
    end
  end

  def dashboard
    @user
    respond_to do |format|
      format.html { render layout: "partner_application" }
    end
  end

  def assigned_task
    @user
    @employee_tasks =  EmployeeAssignTask.where(employee_id:  @user.id,is_completed: false).order("created_at desc")
    render layout: "partner_application"
  end

  def completed_task
    @user
    @employee_tasks =  EmployeeAssignTask.where(employee_id:  @user.id,is_completed: true).order("created_at desc")
    render layout: "partner_application"
  end


  def complete_task
    task_list = EmployeeAssignTask.find_by(employee_id: @user.id,task_list_id: params[:task_list_id])
    task_list.update(is_completed: true)
    flash[:success] = "Task Completed Successfully!"
  end

  def upload_complete_task
    begin
      task_list = EmployeeAssignTask.find_by(employee_id: @user.id,task_list_id: params[:task_list_id])
      image_url = upload_multipart_image(params[:task_list][:url], "task_lists", original_filename=nil)

      if image_url.present?
        task_list.update(is_completed: true,image_url: image_url)
      end
      flash[:success] = "Task Completed Successfully!"
    rescue => e
      flash[:error] = "Something went wrong."
    end
    redirect_to business_assigned_task_path
  end
end
