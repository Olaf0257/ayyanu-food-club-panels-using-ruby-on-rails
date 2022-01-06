class Inventory::InventoriesController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @inventories = Inventory.joins(:article).search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def soh
    filter = {restaurant_id: current_restaurant.id}
    if params[:start_date].present? && params[:end_date].present?
      from_date = params[:start_date].to_date
      to_date = params[:end_date].to_date
      filter.merge!(created_at: from_date.beginning_of_day..to_date.end_of_day) 
    end
    filter.merge!(articles: {over_group_id: params[:over_group_id]}) if params[:over_group_id].present?
    filter.merge!(articles: {major_group_id: params[:major_group_id]}) if params[:major_group_id].present?
    filter.merge!(articles: {item_group_id: params[:item_group_id]}) if params[:item_group_id].present?
    @inventories = Inventory.joins(article: [:major_group, :over_group, :item_group]).where(filter).group_by{|a| [a.article_id, a.article.major_group_id, a.article.over_group_id, a.article.item_group_id, a.article.purchase_price]}
    respond_to do |format|
      format.html
      format.csv { send_data Inventory.to_csv(@inventories), filename: "Inventory-#{Date.today}.csv" }
    end
  end

  def new
    @articles = current_restaurant.articles 
    if params[:purchase_order_id].present?
      @purchase_order = PurchaseOrder.find_by(id: params[:purchase_order_id])
      @inventory = current_restaurant.inventorys.new(purchase_order_id: @purchase_order.id, store_id: @purchase_order.store_id, vendor_id: @purchase_order.vendor_id, delivery_date: @purchase_order.delivery_date)
      @purchase_articles = @purchase_order.purchase_articles
      @purchase_articles.each do |pa|
        @inventory.receive_articles.build(article_id: pa.article_id, quantity: pa.quantity, rate: pa.article.purchase_price) 
      end
    else
      @inventory = current_restaurant.inventorys.new
      @receive_article = @inventory.receive_articles.new
    end
  end

  def create
    @inventory = current_restaurant.inventorys.new(inventory_params)
    if @inventory.save
      flash[:success] = "Created Successfully!"
      if params[:inventory][:purchase_order_id].present?
        redirect_to receive_po_orders_inventory_restaurant_inventorys_path
      else
        redirect_to inventory_restaurant_inventorys_path
      end
    else
      flash[:error] = @inventory.errors.full_messages.join(", ")
      if params[:inventory][:purchase_order_id].present?
        redirect_to receive_po_orders_inventory_restaurant_inventorys_path
      else
        render :new
      end
    end
  end

  def edit
    @inventory = Inventory.find_by(id: params[:id])
  end

  def update
    @inventory = Inventory.find_by(id: params[:id])
    if @inventory.update(inventory_params)
      flash[:success] = "Updated Successfully!"
      redirect_to inventory_restaurant_inventorys_path
    else
      flash[:error] = @inventory.errors.full_messages.join(", ")
      render :edit
    end
  end

  def show
    @inventory = Inventory.find_by(id: params[:id])
    respond_to do |format|
      format.html
    end 
  end

  def destroy
    @inventory = Inventory.find_by(id: params[:id])
    if @inventory.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @inventory.errors.full_messages.join(", ")
    end
    redirect_to inventory_restaurant_inventorys_path
  end

  private

  def inventory_params
    params.require(:inventory).permit(:article_id, :user_id, :restaurant_id, :stock, :inventoryable_type, :inventoryable_id, :receive_article_id).merge!(user_id: @user.id)
  end

end
