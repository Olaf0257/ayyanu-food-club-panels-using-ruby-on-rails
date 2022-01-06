class Inventory::RecipesController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    if params[:operation_type].present?
      @recipes = Recipe.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @recipes = Recipe.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def reject_orders
    @recipes = Recipe.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def reject_recipe
    @recipe = Recipe.find_by(id: params[:id])
    if @recipe.update(rejected_reason: params[:rejected_reason], status: 'cancelled')
      flash[:success] = "Updated Successfully!"
      redirect_back(fallback_location: reject_orders_inventory_restaurant_recipes_path)
    else
      flash[:error] = @recipe.errors.full_messages.join(", ")
    end
  end

  def receive_po_orders
    @purchase_orders = PurchaseOrder.search(params[:keyword]).where(restaurant: current_restaurant, status: 'booked').order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @recipe = current_restaurant.recipes.new
    @ingredients = @recipe.ingredients.new
    @articles = current_restaurant.articles.where(article_type: "Profit Contribution")
    @recipes = current_restaurant.recipes
    @expenses = current_restaurant.articles.where(article_type: "Expenses")
    @recipe_groups = current_restaurant.recipe_groups
  end

  def create
    @recipe = current_restaurant.recipes.new(recipe_params)
    if @recipe.save
      flash[:success] = "Created Successfully!"
      redirect_to inventory_restaurant_recipes_path
    else
      flash[:error] = @recipe.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @articles = current_restaurant.articles.where(article_type: "Profit Contribution")
    @recipe = Recipe.find_by(id: params[:id])
    @ingredients = @recipe.ingredients
    @recipes = current_restaurant.recipes
    @expenses = current_restaurant.articles.where(article_type: "Expenses")
    @recipe_groups = current_restaurant.recipe_groups
  end

  def update
    @recipe = Recipe.find_by(id: params[:id])
    if @recipe.update(recipe_params)
      flash[:success] = "Updated Successfully!"
      redirect_to inventory_restaurant_recipes_path
    else
      flash[:error] = @recipe.errors.full_messages.join(", ")
      render :edit
    end
  end

  def show
    @articles = current_restaurant.articles
    @recipe = Recipe.find_by(id: params[:id])
    @ingredients = @recipe.ingredients
    respond_to do |format|
      format.html
      format.csv { send_data @recipe.articles_list_csv, filename: "po.csv" }
    end 
  end

  def destroy
    @recipe = Recipe.find_by(id: params[:id])
    if @recipe.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @recipe.errors.full_messages.join(", ")
    end
    redirect_to inventory_restaurant_recipes_path
  end

  def display_article_details
    @article = Article.find_by_id(params[:article_id])
  end

  def filter_other_groups_by_type
    if params[:over_group_id].present?
      @major_groups = @restaurant.major_groups.where(over_group_id: params[:over_group_id])
      @item_groups = @restaurant.item_groups.where(major_group: @major_groups.first)
    elsif params[:major_group_id].present?
      @item_groups = @restaurant.item_groups.where(major_group_id: params[:major_group_id])
    end
  end

  def get_portion_units
    if params[:article_id].present?
      article = Article.find_by(id: params[:article_id])
      if article.present? && article&.base_unit.present?
        base_unit = Unit.find_by(id: article&.base_unit)&.base_unit.to_s.strip.downcase
        if base_unit.present?
          @portion_units = Ingredient::PORTION_UNIT[base_unit.to_s]
        end
      end
    end
    if params[:nested_id].present?
      @nested_id = params[:nested_id]
    end
  end

  private

  def recipe_params
    params.require(:recipe).permit(:name, :yields, :total_weight, :restaurant_id, :country_id, :branch_id, :over_group_id, :major_group_id, :recipe_group_id, :unit_id, :user_id, :portion, :portion_size, ingredients_attributes: Ingredient.attribute_names.map(&:to_sym).push(:_destroy, :_id)).merge!(user_id: @user.id)
  end

end
