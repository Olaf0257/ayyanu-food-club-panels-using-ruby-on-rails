class Inventory::TransferOrdersController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def reject_transfer_order
    @transfer_order = TransferOrder.find_by(id: params[:id])
    if @transfer_order.update(rejected_reason: params[:rejected_reason], status: 'rejected')
      flash[:success] = "Updated Successfully!"
      redirect_back(fallback_location: book_orders_inventory_restaurant_transfer_orders_path)
    else
      flash[:error] = @transfer_order.errors.full_messages.join(", ")
    end
  end

  def index
    if params[:operation_type].present?
      @transfer_orders = TransferOrder.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @transfer_orders = TransferOrder.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def approve_orders
    if params[:operation_type].present?
      @transfer_orders = TransferOrder.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type], status: 'pending').order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @transfer_orders = TransferOrder.search(params[:keyword]).where(restaurant: current_restaurant, status: 'pending').order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def process_transfer_orders
    if params[:operation_type].present?
      @transfer_orders = TransferOrder.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type], status: ['approved', 'transfered']).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @transfer_orders = TransferOrder.search(params[:keyword]).where(restaurant: current_restaurant, status: ['approved', 'transfered']).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def process_transfer
    @transfer_order = TransferOrder.find_by(id: params[:transfer_order_id])
    @transfer_order.transfer_inventories
    flash[:success] = "Transfered Successfully!"
    redirect_to process_transfer_orders_inventory_restaurant_transfer_orders_path
  end

  def new
    @articles = current_restaurant.articles.joins(:inventories).uniq
    @sources = params[:source_type].eql?('Station') ? current_restaurant.stations : current_restaurant.stores
    @destinations = params[:destination_type].eql?('Station') ? current_restaurant.stations : current_restaurant.stores 
    @transfer_order = current_restaurant.transfer_orders.new
    @transfer_article = @transfer_order.transfer_articles.new
  end

  def create
    @transfer_order = current_restaurant.transfer_orders.new(transfer_order_params)
    if @transfer_order.save
      flash[:success] = "Created Successfully!"
      redirect_to inventory_restaurant_transfer_orders_path
    else
      flash[:error] = @transfer_order.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @articles = current_restaurant.articles.joins(:inventories).uniq
    @transfer_order = TransferOrder.find_by(id: params[:id])
    @sources = @transfer_order.source_type.eql?('Station') ? current_restaurant.stations : current_restaurant.stores
    @destinations = @transfer_order.destination_type.eql?('Station') ? current_restaurant.stations : current_restaurant.stores 
    @transfer_article = @transfer_order.transfer_articles
  end

  def update
    @transfer_order = TransferOrder.find_by(id: params[:id])
    if @transfer_order.update(transfer_order_params)
      flash[:success] = "Updated Successfully!"
      if params[:commit] == "Update Transfer Order"
        @transfer_order.update(status: 'pending')
        redirect_to inventory_restaurant_transfer_orders_path
      else
        redirect_back(fallback_location: inventory_restaurant_transfer_orders_path)
      end
    else
      flash[:error] = @transfer_order.errors.full_messages.join(", ")
      render :edit
    end
  end

  def show
    @articles = current_restaurant.articles
    @transfer_order = TransferOrder.find_by(id: params[:id])
    @transfer_articles = @transfer_order.transfer_articles
    respond_to do |format|
      format.html
      format.csv { send_data @transfer_order.articles_list_csv, filename: "po.csv" }
    end 
  end

  def destroy
    @transfer_order = TransferOrder.find_by(id: params[:id])
    if @transfer_order.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @transfer_order.errors.full_messages.join(", ")
    end
    redirect_to inventory_restaurant_transfer_orders_path
  end

  def filter_source_by_type
    if params[:source_type].eql?('Store')
      @sources = current_restaurant.stores.where(country_ids: params[:country_id].split)
    elsif params[:source_type].eql?('Station')
      @sources = current_restaurant.stations
    end
  end

  def filter_destination_by_type
    if params[:destination_type].eql?('Store')
      @destinations = current_restaurant.stores.where(country_ids: params[:country_id].split)
    elsif params[:destination_type].eql?('Station')
      @destinations = current_restaurant.stations
    end
  end

  def display_article_details
    @article = Article.find_by_id(params[:article_id])
  end

  private

  def transfer_order_params
    params.require(:transfer_order).permit(:status, :restaurant_id, :country_id, :branch_id, :status, :source_type, :source_id, :destination_type, :destination_id, :delivery_date, :rejected_reason, :id, transfer_articles_attributes: TransferArticle.attribute_names.map(&:to_sym).push(:_destroy, :_id)).merge!(user_id: @user.id)
  end

end
