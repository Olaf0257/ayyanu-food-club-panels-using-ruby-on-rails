class Inventory::ReceiveOrdersController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    if params[:operation_type].present?
      @receive_orders = ReceiveOrder.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @receive_orders = ReceiveOrder.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def reject_orders
    @receive_orders = ReceiveOrder.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def reject_receive_order
    @receive_order = ReceiveOrder.find_by(id: params[:id])
    if @receive_order.update(rejected_reason: params[:rejected_reason], status: 'cancelled')
      flash[:success] = "Updated Successfully!"
      redirect_back(fallback_location: reject_orders_inventory_restaurant_receive_orders_path)
    else
      flash[:error] = @receive_order.errors.full_messages.join(", ")
    end
  end

  def receive_po_orders
    @purchase_orders = PurchaseOrder.search(params[:keyword]).where(restaurant: current_restaurant, status: 'booked').order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @articles = current_restaurant.articles 
    if params[:purchase_order_id].present?
      @purchase_order = PurchaseOrder.find_by(id: params[:purchase_order_id])
      @receive_order = current_restaurant.receive_orders.new(purchase_order_id: @purchase_order.id, store_id: @purchase_order.store_id, vendor_id: @purchase_order.vendor_id, delivery_date: @purchase_order.delivery_date)
      @purchase_articles = @purchase_order.purchase_articles
      @purchase_articles.each do |pa|
        @receive_order.receive_articles.build(article_id: pa.article_id, quantity: pa.quantity, rate: pa.article.purchase_price) 
      end
    else
      @receive_order = current_restaurant.receive_orders.new
      @receive_article = @receive_order.receive_articles.new
    end
  end

  def create
    @receive_order = current_restaurant.receive_orders.new(receive_order_params)
    if @receive_order.save
      flash[:success] = "Created Successfully!"
      if params[:receive_order][:purchase_order_id].present?
        redirect_to receive_po_orders_inventory_restaurant_receive_orders_path
      else
        redirect_to inventory_restaurant_receive_orders_path
      end
    else
      flash[:error] = @receive_order.errors.full_messages.join(", ")
      if params[:receive_order][:purchase_order_id].present?
        redirect_to receive_po_orders_inventory_restaurant_receive_orders_path
      else
        render :new
      end
    end
  end

  def edit
    @articles = current_restaurant.articles
    @receive_order = ReceiveOrder.find_by(id: params[:id])
    @receive_articles = @receive_order.receive_articles
  end

  def update
    @receive_order = ReceiveOrder.find_by(id: params[:id])
    if @receive_order.update(receive_order_params)
      flash[:success] = "Updated Successfully!"
      redirect_to inventory_restaurant_receive_orders_path
    else
      flash[:error] = @receive_order.errors.full_messages.join(", ")
      render :edit
    end
  end

  def show
    @articles = current_restaurant.articles
    @receive_order = ReceiveOrder.find_by(id: params[:id])
    @receive_articles = @receive_order.receive_articles
    respond_to do |format|
      format.html
      format.csv { send_data @receive_order.articles_list_csv, filename: "po.csv" }
    end 
  end

  def destroy
    @receive_order = ReceiveOrder.find_by(id: params[:id])
    if @receive_order.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @receive_order.errors.full_messages.join(", ")
    end
    redirect_to inventory_restaurant_receive_orders_path
  end

  def display_article_details
    @article = Article.find_by_id(params[:article_id])
  end

  private

  def receive_order_params
    params.require(:receive_order).permit(:name, :restaurant_id, :country_id, :branch_id, :status, :purchase_order_id, :store_id, :vendor_id, :van_temp, :invoice_no, :discount, :discount_percentage, :vat_percentage, :stock, :delivery_date, :rejected_reason, :id, receive_articles_attributes: ReceiveArticle.attribute_names.map(&:to_sym).push(:_destroy, :_id)).merge!(user_id: @user.id)
  end

end
