class Master::BrandsController < BrandsController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit]
  layout "partner_application"

  def index
    if params[:branch].present?
      @brands = Brand.search(params[:keyword]).where(restaurant: @restaurant, branch_id: params[:branch]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @brands = Brand.search(params[:keyword]).where(restaurant: @restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @brand = @restaurant.brands.new
  end

  def create
    brand_params_with_phone = brand_params
    brand_params_with_phone[:representative_phone] = params[:representative_phone] if params[:representative_phone].present?
    brand_params_with_phone[:authorised_person_phone] = params[:authorised_person_phone] if params[:authorised_person_phone].present?
    @brand = @restaurant.brands.new(brand_params_with_phone)
    if @brand.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_brands_path
    else
      flash[:error] = @brand.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @brand = Brand.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @brand = Brand.find_by(id: params[:id])
    brand_params_with_phone = brand_params
    brand_params_with_phone[:representative_phone] = params[:representative_phone] if params[:representative_phone].present?
    brand_params_with_phone[:authorised_person_phone] = params[:authorised_person_phone] if params[:authorised_person_phone].present?
    if @brand.update(brand_params_with_phone)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_brands_path
    else
      flash[:error] = @brand.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @brand = Brand.find_by(id: params[:id])
    if @brand.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @brand.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_brands_path
  end

  private

  def brand_params
    params.require(:brand).permit(:name, :restaurant_id, :representative, :representative_phone, :authorised_person, :authorised_person_phone).merge!(user_id: @user.id)
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
