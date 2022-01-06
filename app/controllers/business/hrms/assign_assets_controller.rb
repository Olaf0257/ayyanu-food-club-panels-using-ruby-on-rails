class Business::Hrms::AssignAssetsController < ApplicationController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit, :hand_over]
  layout "partner_application"


  def dashboard
    render layout: "partner_application"
  end

  def index
    @assign_assets = AssignAsset.all.where(restaurant_id: params[:restaurant_id]).order("created_at desc")
    render layout: "partner_application"
  end

  def new
    @asset_types = AssetType.all.where(restaurant_id: @restaurant.id)
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @assign_asset = AssignAsset.new
    # @assign.build_assign_assets
    render layout: "partner_application"
  end

  def create
    assign = AssignAsset.new(assign_params)
    if assign.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = assign.errors.full_messages.first.to_s
    end
    redirect_to business_hrms_assign_assets_path(restaurant_id: params[:restaurant_id])
  end
  def hand_over_list
    @assign_assets = AssignAsset.all.where(restaurant_id: params[:restaurant_id]).order("created_at desc")
    render layout: "partner_application"
  end

  def hand_over
   @asset_types = AssetType.all.where(restaurant_id: @restaurant.id)
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @assign_asset = AssignAsset.find_by(id: params[:id])
    render layout: "partner_application"
  end


  def edit
    @asset_types = AssetType.all.where(restaurant_id: @restaurant.id)
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @assign_asset = AssignAsset.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @assign = AssignAsset.find_by(id: params[:id])

    if params[:assign_asset][:picture].present?
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    response = imagekitio.upload_file(
      file = params[:assign_asset][:picture], # required
      file_name = params[:assign_asset][:picture].original_filename,  # required
      options= {response_fields: 'isPrivateFile, tags', tags: %w[abc def], use_unique_file_name: true,}
    )
  end
    asset_picture  = assign_params.clone
    asset_picture["picture"]  =  response[:response]["url"] if params[:assign_asset][:picture].present?
    
    if @assign.update(asset_picture)
      flash[:success] = "Updated Successfully!"
      if params["type"] == "handover"
       redirect_to hand_over_list_business_hrms_assign_assets_path(restaurant_id: params[:restaurant_id])
      else  
       redirect_to business_hrms_assign_assets_path(restaurant_id: params[:restaurant_id])
      end
    else
      flash[:error] = @assign.errors.full_messages.join(", ")
    end
  end

  def destroy
    @assign = AssignAsset.find_by(id: params[:id])
    if @assign.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_assign_assets_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @assign.errors.full_messages.join(", ")
    end
  end
 
 def view_image
    @assign_asset = AssignAsset.find_by(id: params[:id])
  end

  def department_designation
    asset_type = AssetType.find_by_id(params[:id])
    @assets = asset_type.assets
  end

  def find_asset_list
    @assets = AssetCategory.find_by(id: params[:asset_category_id]).assets    
    render :json => { :success => true,:assets =>@assets }
  end

  private

  def assign_params
    params.require(:assign_asset).permit(:valid_till, :returned_on, :remarks, :restaurant_id, :user_id, :asset_type_id, :asset_status, :asset_category_id, :asset_id, :picture)
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
