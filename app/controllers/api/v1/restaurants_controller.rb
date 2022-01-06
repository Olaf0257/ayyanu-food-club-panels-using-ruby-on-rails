class Api::V1::RestaurantsController < Api::ApiController
  before_action :authenticate_guest_access, except: [:branch_menu, :branch_reviews]
  # ,except: [:restaurant_list,:restaurant_menu_category,:search_by_category,:restaurant_branch_list,:addon_item,:category_list,:restaurant_branch_menu,:update_category]
  before_action :validate_transporter, only: [:add_branch_transporter]
  # before_action :validate_iou,only: [:add_iou]
  def restaurant_branch_menu
    branch = get_restaurant_branch(params[:branch_id])
    if branch
      most_selling = Branch.get_most_selling_data(branch, @user, @guestToken, params[:image_width], request.headers["language"], params[:area_id])
      menu = get_branch_menu_list(@user, @guestToken, branch, params[:image_width], request.headers["language"], most_selling.present? ? most_selling["items"].pluck("id") : [], params[:area_id], params[:keyword])
      # daily_dishes = get_daily_dishes_data(branch)
      count = 0
      # daily_dishes.present? ? daily_dishes.category_priority : 0
      area = branch.branch_coverage_areas.where(coverage_area_id: params[:area_id]).first
      data = area.present? ? area.coverage_area.as_json(language: request.headers["language"]) : CoverageArea.find_by(id: params[:area_id]).as_json(language: request.headers["language"])
      responce_json(code: 200, data: most_selling.present? ? menu_json(menu, request.headers["language"], params[:branch_id]).insert(count, most_selling) : menu_json(menu, request.headers["language"], params[:branch_id]), branch: branch.as_json(logdinUser: @user, areaWies: params[:area_id], language: request.headers["language"], only: [:id]).merge(coverage_area: data))
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  def addon_item
    item = get_menu_item(params[:item_id])
    if item.item_addon_categories
      addonItem = get_addon_item_list(item, @user, request.headers["language"])
      responce_json(code: 200, data: addonItem)
    else
      responce_json(code: 422, message: "Addon not available!!")
    end
  end

  def restaurant_menu_category
    branch = get_restaurant_branch(params[:branch_id])
    if branch
      menuCategories = get_branch_menu_categories(branch, params[:area_id])
      most_selling = Branch.get_most_selling_data(branch, @user, @guestToken, params[:image_width], request.headers["language"], params[:area_id])
      if most_selling.present?
        most_selling.delete("items")
        menuCategories.insert(0, most_selling)
      end
      responce_json(code: 200, data: menuCategories.as_json(language: request.headers["language"]), total_items: menuCategories.count)
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  def restaurant_list
    restaurant_data = get_all_restaurant_Branch(params[:area_id], params[:sort_key], params[:sort_by], params[:offres], params[:free_delivery], params[:open_resturant], params[:payment_method], params[:page], params[:per_page], "", params[:new_restaurant])
    responce_json(code: 200, data: restaurant_json(restaurant_data, request.headers["language"], params[:area_id]), total_pages: restaurant_data.total_pages, restaurant_count: restaurant_data.total_entries)
    rescue Exception => e
  end

  def category_list
    categories = get_all_category(params[:page], params[:per_page])
    responce_json(code: 200, categories: home_json(categories, @user, request.headers["language"]))
  end

  def party_list
    country_id = CoverageArea.find(params[:area_id]).country_id
    result = Point.sellable_restaurant_wise_points(country_id)
    responce_json(code: 200, data: party_category_json(result, @user, request.headers["language"]))
  end

  def search_by_category
    restaurants = search_restaurant_by_category(params[:category_id], params[:area_id], params[:page], params[:per_page])
    responce_json(code: 200, data: restaurant_category_json(restaurants, request.headers["language"], params[:area_id]), total_pages: restaurants.total_pages)
  end

  def restaurant_branch_list
    branches = get_restaurant_all_branch(params[:restaurant_id])
    responce_json(code: 200, data: web_restaurant_branch_json(branches))
  end

  def make_favorite
    if params[:branch_id]
      favorite = get_favorite_branch(@user, params[:branch_id])
      if !favorite
        favorite = add_branch_to_favorite(@user, params[:branch_id])
        responce_json(code: 200, status: true)
      else
        favorite.branch.update(is_favorite: false)
        favorite.destroy
        responce_json(code: 200, status: false)
      end
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  def favorite_list
    favorites = @user.favorites.paginate(page: params[:page], per_page: params[:per_page])
    responce_json(code: 200, message: "successfully", favorite_branches: get_user_favorites(favorites), total_pages: favorites.total_pages)
  end

  def branch_transporter
    branch = Branch.joins(:restaurant).where("restaurants.user_id=? and branches.id=?", @user.id, params[:branch_id]).first
    if branch
      transporters = find_branch_transporter(branch)
      transporters.present? ? responce_json(code: 200, transporters: transporters_json(transporters, params[:order_id])) : responce_json(code: 422, message: "Transporter not available!!")
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  # Only for Test create transporter
  def add_branch_transporter
    transporter = add_transporter(params[:branch_id], params[:user_id])
    responce_json(code: 200, message: "successfully")
  end

  # def add_iou
  #   iou = add_transporter_iou(@user,params[:order_id],params[:transporter_id],params[:amount])
  #   responce_json({code: 200, message: "successfully" ,iou: iou_json(iou)})
  # end

  def add_category
    category = add_new_category(params[:title], params[:image])
    responce_json(code: 200, message: "successfully added", category: category)
  end

  def update_category
    category = get_category_details(params[:category_id])

    if category
      prev_img = category.icon.present? ? category.icon.split("/").last : "n/a"
      uploadImage = params[:image].present? ? update_multipart_image(prev_img, params[:image], "categories") : category.icon
      updateRecord = update_category_info(category, params[:title], uploadImage, params[:color])
      responce_json(code: 200, message: "successfully updated", category: category)
    else
      responce_json(code: 404, message: "Not found")
    end
  end

  def branch_reviews
    if params[:branch_id]
      branch = get_branch(params[:branch_id])
      ratingData = get_branch_ratings(branch)
      reviews = branch.ratings.order("id DESC").paginate(page: params[:page], per_page: params[:per_page])
      responce_json(code: 200, reviews: reviews_json(reviews), rating: ratingData)
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  def branch_menu
    branch = get_branch(params[:branch_id])
    if branch
      menu = get_branch_menu(branch)
      responce_json(code: 200, menue_items: menu)
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  private

  def validate_transporter
    bussines_user = @user.auths.find_by(role: "business")
    business_transporter = get_business_transporter(params[:user_id], params[:branch_id])
    user = find_user(params[:user_id])
    auth = get_user_auth(user, "transporter")
    unless bussines_user && business_transporter.blank? && auth
      responce_json(code: 422, message: (bussines_user ? business_transporter ? "Transporter already added" : "Invalid transporter" : "Invalid user").to_s)
    end
  end

  # def validate_iou
  #   bussines_user = @user.auths.where("role = ? or role = ?","business","manager")
  #   business_transporter = get_business_transporter(params[:transporter_id],params[:branch_id])
  #   order = get_order_type(params[:order_id])
  #   iou_order = get_iou_order(params[:order_id])
  #   user = find_user(params[:transporter_id])
  #    auth = get_user_auth(user,"transporter")
  #    unless bussines_user and business_transporter and auth and order and params[:order_id] and params[:amount] and !iou_order
  #      responce_json({code: 422, message: "#{bussines_user ? "Required parameter messing!!" : "Invalid user" }" })
  #    end
  # end
end
