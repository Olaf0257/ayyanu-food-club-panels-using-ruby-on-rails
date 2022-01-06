class Business::Setup::StagesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @stages = @restaurant.stages
    @stages = @stages.where("name LIKE ? OR created_at LIKE ?", "%#{params[:keyword]}%","%#{params[:keyword]}%") if params[:keyword].present?
    @stages = Stage.all.map{|s| s if s.created_by.name == params[:keyword]}.compact unless @stages.present?
  end

  def new
     @stage = Stage.new
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @stage = @restaurant.stages.new(stage_params)
    if @stage.save
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_stages_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @stage.errors.full_messages.join(", ")
    end
  end

  def edit
    @stage = Stage.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @stage = Stage.find_by(id: params[:id])
    if @stage.update(stage_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_stages_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @vendor.errors.full_messages.join(", ")
    end
  end

  def destroy
    @stage = Stage.find_by(id: params[:id])
    if @stage.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_stages_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] =  @stage.errors.full_messages.join(", ")
    end
  end


  private
 

  def stage_params
    params.require(:stage).permit(:bank,:enabled,:date,
                                      :depositor_number,
                                      :account_name,
                                      :account_number,
                                      :note,
                                      :serial_number,
                                      :vendor_name,
                                      :autorize_person,
                                      :employee_name,
                                      :vendor_number,
                                      :card_types,
                                      :number_of_machine,
                                      :deduction_type,
                                      :amounts,
                                      :exchange_name,
                                      :person_recieve
                                    ).merge(created_by_id: @user.id,name: params[:name])
  end
end
