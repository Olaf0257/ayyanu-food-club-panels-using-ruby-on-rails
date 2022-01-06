class Business::AssetManagement::AssetsController < ApplicationController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit, :update]
  layout "partner_application"

  require "roo"
  require "barby/barcode/qr_code"
  require "barby/outputter/svg_outputter"

  def index
    @add_assets = @restaurant.assets.order("created_at DESC")
  end

  def new
    @asset_types = @restaurant.asset_types
    @branches = @restaurant.branches
    @add_asset = Asset.new
  end
  
  def view_QR_Code
    @asset = Asset.find(params[:id])
  end 

  def view_image
    @asset = Asset.find(params[:id])
  end

  def create
    @add_asset = @restaurant.assets.new(add_asset_params)
    if params[:asset][:asset_pic_upload].present?
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    response = imagekitio.upload_file(
      file = params[:asset][:asset_pic_upload], # required
      file_name = params[:asset][:asset_pic_upload].original_filename,  # required
      options= {response_fields: 'isPrivateFile, tags', tags: %w[abc def], use_unique_file_name: true,}
    )
   @add_asset.asset_pic_upload = response[:response]["url"]
  end
   @add_asset.barcode_url = generate_qr_code
    if @add_asset.save
      flash[:success] = "Created Successfully!"
      redirect_to business_asset_management_assets_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @add_asset.errors.full_messages.join(", ")
    end
  end


  def generate_qr_code
    Barby::QrCode.new(@add_asset.asset_pic_upload, level: :q, size: 10).to_svg(margin: 0)
  end

  def edit
    @asset_types = @restaurant.asset_types
    @branches = @restaurant.branches
    @add_asset = Asset.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @add_asset = Asset.find_by(id: params[:id])
    @add_asset.restaurant_id = @restaurant.id

    if params[:asset][:asset_pic_upload].present?
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    response = imagekitio.upload_file(
      file = params[:asset][:asset_pic_upload], # required
      file_name = params[:asset][:asset_pic_upload].original_filename,  # required
      options= {response_fields: 'isPrivateFile, tags', tags: %w[abc def], use_unique_file_name: true,}
    )
  end
    asset_picture  = add_asset_params.clone
    asset_picture["asset_pic_upload"]  =  response[:response]["url"] if params[:asset][:asset_pic_upload].present?
    
    if @add_asset.update(asset_picture)
      flash[:success] = "Updated Successfully!"
      redirect_to business_asset_management_assets_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @add_asset.errors.full_messages.join(", ")
    end
  end

  def destroy
    @add_asset = Asset.find_by(id: params[:id])
    if @add_asset.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_asset_management_assets_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @add_asset.errors.full_messages.join(", ")
    end
  end
 
  def find_asset_type_list
    @asset_types = AssetType.find_by(id: params[:asset_category_id]).asset_categories    
    render :json => { :success => true,:asset_types =>@asset_types }
  end

  private

  def add_asset_params
    params.require(:asset).permit(:name,:asset_category_id, :location_available, :brand_id, :model, :serial_number, :purchase_date, :invoice_number, :asset_pic_upload, :current_value, :original_value, :warranty, :asset_type_id, :branch_id,:country_of_origin,:station_id,:hs_code,:item_description, :picture)
  end

   def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
