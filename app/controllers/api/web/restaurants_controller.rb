class Api::Web::RestaurantsController < Api::ApiController
  def category_list
    categories = get_all_category(1, 20)
    responce_json(code: 200, categories: categories.as_json(language: request.headers["language"]))
  end

  def search_restaurant
    api_key = request.headers["HTTP_ACCESSTOKEN"]
    serverSession = ServerSession.where(server_token: api_key).first
    @user = serverSession.present? ? serverSession.auth.present? ? serverSession.auth.user : nil : nil
    restaurants = get_all_restaurant_Branch(params[:area_id], params[:sort_key], params[:sort_by], params[:offres], params[:free_delivery], params[:open_restaurant], params[:payment_method], params[:page], params[:per_page], params[:category_id], params[:new_restaurant])
    responce_json(code: 200, data: web_branch_json(restaurants), restaurant_count: restaurants.total_entries, total_pages: restaurants.total_pages)
    rescue Exception => e
  end

  def web_category_list
    categories = get_all_category(params[:page], params[:per_page])
    responce_json(code: 200, categories: categories.as_json(language: request.headers["language"]))
  end

  def web_restaurant_branch_menu
    branch = get_restaurant_branch(params[:branch_id])
    if branch
      most_selling = Branch.get_most_selling_data(branch, params[:area_id])
      daily_dishes = get_daily_dishes_data(branch)
      count = daily_dishes.present? ? 1 : 0
      menu = get_branch_menu_list(@user, nil, branch, params[:image_width], request.headers["language"], "", "", params[:keyword])
      responce_json(
        code: 200,
        data: most_selling.present? ? menu_json(menu, request.headers["language"], branch).insert(count, most_selling) : menu_json(menu, request.headers["language"], branch),
        branch: branch.as_json(only: [:id, :min_order_amount, :cash_on_delivery, :accept_cash, :accept_card, :daily_timing, :delivery_charges, :contact], include: [coverage_area: { only: [:id, :area] }])
      )
    else
      responce_json(code: 422, message: "Branch not available!!")
    end
  end

  def web_addon_item
    item = get_menu_item(params[:item_id])
    if item.item_addon_categories
      addonItem = get_addon_item_list(item, "", request.headers["language"])
      responce_json(code: 200, data: addonItem)
    else
      responce_json(code: 422, message: "Addon not available!!")
    end
  end

  def web_restaurant_list
    restaurants = get_all_restaurants(params[:keyword], params[:page], params[:per_page])
    p restaurants
    responce_json(code: 200, data: web_restaurant_json(restaurants), restaurant_count: restaurants.count, total_pages: restaurants.total_pages)
  end
end
