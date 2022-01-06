class Master::ArticlesController < BrandsController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit, :filter_groups_by_type]
  layout "partner_application"

  def index
    @currency = @restaurant.country.try(:currency_code)
    @types = ["Profit Contribution", "Expenses"]
    if params[:operation_type].present?
      @articles = Article.search(params[:keyword]).where(restaurant: @restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @articles = Article.search(params[:keyword]).where(restaurant: @restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @article = @restaurant.articles.new
    @major_groups = @restaurant.major_groups
    @over_groups = @restaurant.over_groups
    @item_groups = @restaurant.item_groups
    @base_units = @restaurant.units
    @taxes = Tax.where(country: @restaurant.country)
    @currency = @restaurant.country.try(:currency_code)
  end

  def create
    @article = @restaurant.articles.new(article_params)
    if @article.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_articles_path
    else
      flash[:error] = @article.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @article = Article.find_by(id: params[:id])
    @major_groups = @restaurant.major_groups
    @over_groups = @restaurant.over_groups
    @item_groups = @restaurant.item_groups
    @base_units = @restaurant.units
    @taxes = Tax.where(country: @restaurant.country)
    @currency = @restaurant.country.try(:currency_code)
    render layout: "partner_application"
  end

  def update
    @article = Article.find_by(id: params[:id])
    if @article.update(article_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_articles_path
    else
      flash[:error] = @article.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @article = Article.find_by(id: params[:id])
    if @article.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @article.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_articles_path
  end

  def filter_groups_by_type
    if params[:over_group_id].present?
      @major_groups = @restaurant.major_groups.where(over_group_id: params[:over_group_id])
      @item_groups = @restaurant.item_groups.where(major_group: @major_groups.first)
    elsif params[:major_group_id].present?
      @item_groups = @restaurant.item_groups.where(major_group_id: params[:major_group_id])
    end
  end

  private

  def article_params
    params.require(:article).permit(:name, :restaurant_id, :major_group_id, :article_type, :price_type, :over_group_id, :barcode, :item_group_id, :purchase_price, :planned_price, :calorie, :base_unit, :store_unit, :expires_in, :weight, taxes: []).merge!(user_id: @user.id)
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
