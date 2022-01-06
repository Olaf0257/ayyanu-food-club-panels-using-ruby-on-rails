class Inventory::PurchaseOrdersController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def dashboard
  end

  def reject_purchase_order
    @purchase_order = PurchaseOrder.find_by(id: params[:id])
    if @purchase_order.update(rejected_reason: params[:rejected_reason], status: 'rejected')
      flash[:success] = "Updated Successfully!"
      redirect_back(fallback_location: book_orders_inventory_restaurant_purchase_orders_path)
    else
      flash[:error] = @purchase_order.errors.full_messages.join(", ")
    end
  end

  def index
    if params[:operation_type].present?
      @purchase_orders = PurchaseOrder.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @purchase_orders = PurchaseOrder.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def book_orders
    if params[:operation_type].present?
      @purchase_orders = PurchaseOrder.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @purchase_orders = PurchaseOrder.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @articles = current_restaurant.articles
    @purchase_order = current_restaurant.purchase_orders.new
    @purchase_article = @purchase_order.purchase_articles.new
  end

  def create
    @purchase_order = current_restaurant.purchase_orders.new(purchase_order_params)
    if @purchase_order.save
      flash[:success] = "Created Successfully!"
      redirect_to inventory_restaurant_purchase_orders_path
    else
      flash[:error] = @purchase_order.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @articles = current_restaurant.articles
    @purchase_order = PurchaseOrder.find_by(id: params[:id])
    @purchase_article = @purchase_order.purchase_articles
  end

  def update
    @purchase_order = PurchaseOrder.find_by(id: params[:id])
    if @purchase_order.update(purchase_order_params)
      flash[:success] = "Updated Successfully!"
      if params[:commit] == "Update Purchase Order"
        @purchase_order.update(status: 'pending')
        redirect_to inventory_restaurant_purchase_orders_path
      else
        redirect_back(fallback_location: inventory_restaurant_purchase_orders_path)
      end
    else
      flash[:error] = @purchase_order.errors.full_messages.join(", ")
      render :edit
    end
  end

  def show
    @articles = current_restaurant.articles
    @purchase_order = PurchaseOrder.find_by(id: params[:id])
    @purchase_articles = @purchase_order.purchase_articles
    respond_to do |format|
      format.html
      format.csv { send_data @purchase_order.articles_list_csv, filename: "po.csv" }
    end 
  end

  def destroy
    @purchase_order = PurchaseOrder.find_by(id: params[:id])
    if @purchase_order.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @purchase_order.errors.full_messages.join(", ")
    end
    redirect_to inventory_restaurant_purchase_orders_path
  end

  def filter_groups_by_type
    if params[:over_group_id].present?
      @major_groups = current_restaurant.major_groups.where(over_group_id: params[:over_group_id])
      @item_groups = current_restaurant.item_groups.where(major_group: @major_groups.first)
    elsif params[:major_group_id].present?
      @item_groups = current_restaurant.item_groups.where(major_group_id: params[:major_group_id])
    end
  end

  def display_article_details
    @article = Article.find_by_id(params[:article_id])
  end

  private

  def purchase_order_params
    params.require(:purchase_order).permit(:name, :restaurant_id, :country_id, :branch_id, :status, :store_id, :vendor_id, :unit_id, :delivery_date, :rejected_reason, :id, purchase_articles_attributes: PurchaseArticle.attribute_names.map(&:to_sym).push(:_destroy, :_id)).merge!(user_id: @user.id)
  end
  
end
