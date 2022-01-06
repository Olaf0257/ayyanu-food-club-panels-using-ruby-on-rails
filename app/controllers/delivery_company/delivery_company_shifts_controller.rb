class DeliveryCompany::DeliveryCompanyShiftsController < ApplicationController
  before_action :authenticate_business

  def index
    @shifts = @user.delivery_company.delivery_company_shifts.order(:day, :start_time)

    respond_to do |format|
      format.html { render layout: "partner_application" }
      format.csv  { send_data @shifts.shift_list_csv(@user.delivery_company&.name), filename: "shifts_list.csv" }
    end
  end

  def new
    @shift = @user.delivery_company.delivery_company_shifts.new
    render layout: "partner_application"
  end

  def create
    @shift = @user.delivery_company.delivery_company_shifts.new(shift_params)

    if @shift.save
      flash[:success] = "Shift Created Successfully!"
      redirect_to delivery_company_delivery_company_shifts_path
    else
      flash[:error] = @shift.errors.full_messages.first.to_s
      redirect_to new_delivery_company_delivery_company_shift_path
    end
  end

  def edit
    @shift = @user.delivery_company.delivery_company_shifts.find(params[:id])
    render layout: "partner_application"
  end

  def update
    @shift = @user.delivery_company.delivery_company_shifts.find(params[:id])

    if @shift.update(shift_params)
      flash[:success] = "Shift Updated Successfully!"
      redirect_to delivery_company_delivery_company_shifts_path
    else
      flash[:error] = @shift.errors.full_messages.first.to_s
      redirect_to edit_delivery_company_delivery_company_shift_path(@shift.id)
    end
  end

  def show
    @shift = @user.delivery_company.delivery_company_shifts.find(params[:id])
    @drivers = @shift.users.reject_ghost_driver.order(:name)
    render layout: "partner_application"
  end

  def free_driver_list
    @shift = @user.delivery_company.delivery_company_shifts.find(params[:id])
    @all_drivers = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" }).distinct
    @drivers = @all_drivers.where.not(id: @shift.users.pluck(:id)).reject_ghost_driver.order(:name)
    @drivers = @drivers.where("name like ? ", "%#{params[:keyword]}%").order(:name) if params[:keyword].present?
  end

  def add_driver_to_shift
    shift_id = params[:shift_id]
    shift = DeliveryCompanyShift.find(shift_id)

    if params[:driver_ids].present?
      params[:driver_ids].each do |driver_id|
        shift.users << User.find(driver_id)
      end

      flash[:success] = "Drivers Successfully Added to Shift!"
    else
      flash[:error] = "Please Select Driver to Add"
    end

    redirect_to request.referer
  end

  def remove_driver_from_shift
    shift_id = params[:shift_id]
    user_id = params[:driver_id]
    DeliveryCompanyShift.find(shift_id).users.delete(user_id)
    render json: { code: 200 }
  end

  def destroy
    @shift = @user.delivery_company.delivery_company_shifts.find(params[:id])

    if @shift.destroy
      flash[:success] = "Shift Deleted Successfully!"
    else
      flash[:error] = "Shift Cannot be Deleted"
    end

    redirect_to delivery_company_delivery_company_shifts_path
  end

  private

  def shift_params
    params.require(:delivery_company_shift).permit(:start_time, :end_time, :day, :delivery_company_id)
  end
end
