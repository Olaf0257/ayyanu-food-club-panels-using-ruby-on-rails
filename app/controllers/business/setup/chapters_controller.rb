class Business::Setup::ChaptersController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @chapters = @restaurant.chapters.all.order("created_at DESC")
    @chapters = @chapters.where("chapter_title LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @chapter = Chapter.new
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @chapter = @restaurant.chapters.new(chapter_params)
    @chapter.restaurant_id = @restaurant.id
    
    if params[:chapter][:pdf_document].present?
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    response = imagekitio.upload_file(
      file = params[:chapter][:pdf_document], # required
      file_name = params[:chapter][:pdf_document].original_filename,  # required
      options= {response_fields: 'isPrivateFile, tags', tags: %w[abc def], use_unique_file_name: true,}
    )
    @chapter.pdf_document = response[:response]["url"]
  end

    if @chapter.save
       params[:user_ids].each do |user_id|
        ChapterEmpolyee.create(user_id: user_id,chapter_id: @chapter.id)
       end if params[:user_ids].present? 
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_restaurant_chapters_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @chapter.errors.full_messages.join(", ")
    end
  end
   
  def show
    @chapter = Chapter.find_by(id: params[:id])
  end

  def edit
    @chapter = Chapter.find_by(id: params[:id])
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    render layout: "partner_application"
  end

  def update
    @chapter = Chapter.find_by(id: params[:id])

    if params[:chapter][:pdf_document].present?
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    response = imagekitio.upload_file(
      file = params[:chapter][:pdf_document], # required
      file_name = params[:chapter][:pdf_document].original_filename,  # required
      options= {response_fields: 'isPrivateFile, tags', tags: %w[abc def], use_unique_file_name: true,}
    )
    @chapter.pdf_document = response[:response]["url"]
  end
    chapter_document  = chapter_params.clone
    chapter_document["pdf_document"]  =  response[:response]["url"] if params[:chapter][:pdf_document].present?
    
    if @chapter.update(chapter_document)
      if params[:user_ids].present?
        users = @chapter.users.pluck(:id)-params[:user_ids].map(&:to_i) 
        users.each do |user_id|
         @chapter_empolyee = ChapterEmpolyee.find_by(chapter_id: @chapter.id, user_id: user_id)
         @chapter_empolyee.destroy
        end
        params[:user_ids].each do |user_id|
          @chapter.chapter_employees.find_or_create_by(chapter_id: @chapter.id, user_id: user_id)
        end
      else
         @chapter.chapter_employees.destroy_all
      end  
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_restaurant_chapters_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @chapter.errors.full_messages.join(", ")
    end
  end

  def destroy
    @chapter = Chapter.find_by(id: params[:id])
    if @chapter.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_restaurant_chapters_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @chapter.errors.full_messages.join(", ")
    end
  end

  private

  def chapter_params
    params.require(:chapter).permit(:manual_id, :chapter_title, :pdf_document).merge(created_by_id: @user.try(:id))
  end
end
