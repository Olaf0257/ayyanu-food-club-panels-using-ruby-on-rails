module Api::V1::HomesHelper
  def home_json(categories, user, language)
    categories.as_json(logdinUser: user, language: language)
  end

  def party_category_json(result, user, language)
    data = []

    result.each do |user_id, rest_id|
      user = User.find(user_id)
      restaurant = Restaurant.find(rest_id)
      restaurant.language = language
      data += [user: user.as_json(only: [:id, :name, :email, :country_id], language: language), restaurant: restaurant.as_json(only: [:id, :logo, :country_id], methods: [:title, :currency_code_en, :currency_code_ar], language: language), available_points: helpers.number_with_precision(50, precision: 3), discount: "50%", selling_price: helpers.number_with_precision(25, precision: 3)]
    end

    data
  end

  def get_user_favorites(favorites)
    favorites.as_json(include: { branch: favorite_branches_except_attributes }).map do |rec|
      rec["branch"]["is_favorite"] = true if rec["branch"].present?
      rec
    end
  end

  def home_page_data(area_id, image_width, banner_img_width, user, language)
    page = 1
    per_page = 10
    branch_page = params[:page].presence || 1
    branch_per_page = params[:per_page].presence || 10
    restaurants_branch = get_restaurant_Branch(branch_page, branch_per_page, area_id) # branch data area wise
    categories = get_category(page, per_page, area_id)
    advertisements = get_advertisement(page, per_page)
    { categories_count: categories.count, categories_total_page: categories.total_pages, restaurant_count: restaurants_branch.total_entries, restaurant_total_page: restaurants_branch.total_pages, categories: home_json(categories, user, language), restaurants: restaurants_branch.as_json(only: [:id], imgWidth: image_width, language: language, areaWies: area_id), advertisements: advertisements.as_json(imgWidth: banner_img_width) }
  end

  def get_category(page, per_page, area_id)
    categories = Category.find_category(page, per_page)
    categories = categories.where.not(title: "Party") if Point.sellable_restaurant_wise_points(CoverageArea.find_by(id: area_id)&.country_id).empty?
    categories
  end

  def get_advertisement(page, per_page)
    adds = Advertisement.find_advertisement(page, per_page)
  end

  def get_restaurant_Branch(page, per_page, area_id)
    Branch.find_restaurant_Branch(page, per_page, area_id)
  end

  def get_restaurants(page, per_page, area_id)
    Branch.find_restaurants(page, per_page, area_id)
  end

  def get_all_restaurant_Branch(area_id, sort_key, sort_by, offres, free_delivery, open_restaurant, payment_methodpage, page, per_page, categor_id, new_restaurant)
    offresData = to_boolean(offres)
    free_deliveryData = to_boolean(free_delivery)
    open_resturantData = to_boolean(open_restaurant)
    new_resturantData = to_boolean(new_restaurant)
    Branch.find_all_restaurant_Branch(area_id, sort_key, sort_by, offresData, free_deliveryData, open_resturantData, payment_methodpage, page, per_page, categor_id, new_resturantData)
  end

  def new_home_page_data(area_id, image_width, banner_img_width, user, language)
    top_items_data = []
    page = params[:page].presence || 1
    per_page = params[:per_page].presence || 10
    advertisements = get_advertisement(page, per_page)
    categories = Category.order_by_title
    offers = get_offers_list(area_id, page, per_page)
    order_history = @user ? get_order_list(@user, page, per_page) : []
    re_order_history = @user ? Order.where(user_id: @user.id, is_delivered: true).order(id: "DESC").paginate(page: page, per_page: per_page) : []
    point_list = @user ? get_user_point(@user, page, per_page, language) : {}
    all_branches = Branch.joins(:branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("branch_coverage_areas.coverage_area_id = ? and restaurants.is_signed = (?) and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?)", area_id, true, true, true, true, true).distinct.order_branches
    free_delivery_restaurants = all_branches.where("(branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.delivery_charges = ?) OR (branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.third_party_delivery_type = ?)", false, "0", true, "Free").paginate(page: page, per_page: per_page)
    latest_restaurants = all_branches.reorder("branch_coverage_areas.created_at DESC").limit(10)
    suggested_restaurants = all_branches.limit(5)
    top_items = Order.joins(:order_items).where(order_items: { menu_item_id: all_branches.pluck("menu_items.id").uniq }).group("menu_item_id").order("count(menu_item_id) DESC").limit(20).count

    top_items.each do |item_id, _count|
      i = MenuItem.find(item_id)
      branch_address = language.to_s == "arabic" && i.menu_category.branch.address_ar.present? ? i.menu_category.branch.address_ar : i.menu_category.branch.address
      restaurant_name = language.to_s == "arabic" && i.menu_category.branch.restaurant.title_ar.present? ? i.menu_category.branch.restaurant.title_ar : i.menu_category.branch.restaurant.title

      top_items_data << { id: i.id, name: (language == "arabic" ? i.item_name_ar : i.item_name), branch_id: i.menu_category.branch_id, branch_address: branch_address, restaurant_id: i.menu_category.branch.restaurant_id, restaurant_name: restaurant_name, item_details: i.as_json(language: language) }
    end

    { total_point: (@user ? point_list[:totalPoint] : 0.0), categories: home_json(categories, user, language), advertisements: advertisements.as_json(imgWidth: banner_img_width), offers: offer_json(offers), order_history: order_list_json(order_history, language, area_id), re_order_history: order_list_json(re_order_history, language, area_id), points: (@user ? point_list[:point] : []), free_delivery_restaurants: free_delivery_restaurants.as_json(only: [:id], imgWidth: image_width, language: language, areaWies: area_id), latest_restaurants: latest_restaurants.as_json(only: [:id], imgWidth: image_width, language: language, areaWies: area_id), suggested_restaurants: suggested_restaurants.as_json(only: [:id], imgWidth: image_width, language: language, areaWies: area_id), top_items: top_items_data }
  end

  def branch_except_attributes(_branch)
    { except: [:created_at, :updated_at, :image] }
  end

  def get_all_category(page, per_page)
    categories = Category.find_all_category(page, per_page)
    categories = categories.where.not(title: "Party") if Point.sellable_restaurant_wise_points(nil).empty?
  end

  def get_restaurant_all_branch(restaurant_id)
    Branch.find_restaurant_all_Branch(restaurant_id)
  end

  def get_suggest_search_data(area, language)
    suggesttext = params[:suggest_text]
    result = []
    @categories = search_category(area, suggesttext)
    @branches = search_branches(area, suggesttext)

    @categories.each do |c|
      result << { id: c.id, lowercasename: language == "arabic" ? c.title_ar.downcase : c.title.downcase, name: language == "arabic" ? c.title_ar : c.title, category: language == "arabic" ? "مجموعة" : "Collection", image: c.icon, restaurant_id: 0 }
    end

    @branches.each do |b|
      r = b.restaurant
      areaData = b.branch_coverage_areas.select { |bca| bca.coverage_area_id == area&.id }
      coverage_area = areaData.present? ? areaData.first : b.branch_coverage_areas.first
      data = result.pluck(:restaurant_id).include?(r.id)

      if data == false
        result << { id: b.id, lowercasename: language == "arabic" ? r.title_ar.present? ? r.title_ar.downcase : r.title.downcase : r.title.downcase, name: language == "arabic" ? r.title_ar : r.title, category: language == "arabic" ? "مطعم" : "Restaurant", branch_address: language == "arabic" ? b.address_ar : b.address, image: r.logo, area_id: coverage_area.coverage_area_id, status: b.status, restaurant_id: r.id, is_closed: coverage_area.is_closed, is_busy: coverage_area.is_busy, poll: !b.is_approved }
      end
    end

    result
  end

  def get_suggest_item_search_data(area, language)
    page = params[:page].presence || 1
    per_page = params[:per_page].presence || 10
    suggesttext = params[:suggest_text]
    maxCount = per_page
    result = []
    @menu_items = search_menu_item(nil, area, suggesttext, page, per_page)
    @polling_branches = search_polling_branches(area, suggesttext, page, per_page)
    @branch_without_area = search_branches_without_area(area, suggesttext, page, per_page)
    @branches = @polling_branches + @branch_without_area

    @branches.each do |b|
      r = b.restaurant
      areaData = b.branch_coverage_areas.select { |bca| bca.coverage_area_id == area&.id }
      coverage_area = areaData.present? ? areaData.first : b.branch_coverage_areas.first
      data = result.pluck(:restaurant_id).include?(r.id)

      if data == false
        result << { id: b.id, lowercasename: language == "arabic" ? r.title_ar.present? ? r.title_ar.downcase : r.title.downcase : r.title.downcase, name: language == "arabic" ? r.title_ar : r.title, category: language == "arabic" ? "مطعم" : "Restaurant", branch_address: language == "arabic" ? b.address_ar : b.address, image: r.logo, area_id: coverage_area.coverage_area_id, status: b.status, restaurant_id: r.id, is_closed: coverage_area.is_closed, is_busy: coverage_area.is_busy, poll: !b.is_approved }
      end
    end

    @menu_items.each do |i|
      result << { id: i.id, lowercasename: language == "arabic" ? i.item_name_ar.downcase : i.item_name.downcase, name: language == "arabic" ? i.item_name_ar : i.item_name, category: language == "arabic" ? "بند" : "Item", branch_id: i.menu_category.branch_id, restaurant_id: i.menu_category.branch.restaurant_id, restaurant_name: i.menu_category.branch.restaurant.title, item_details: i.as_json }
    end

    result
  end

  def add_branch_to_favorite(user, branch_id)
    Favorite.add_favorite(user, branch_id)
  end

  def get_favorite_branch(user, branch_id)
    Favorite.find_favorite(user, branch_id)
  end

  def firebase_connection
    base_uri = "https://foodclub-34cb3.firebaseio.com/"
    firebase = Firebase::Client.new(base_uri)
  end

  def create_track_group(firebase, transp_id, lat, long)
    p "======transp_id========#{transp_id}======="
    orders = Order.find_orders_list(transp_id).pluck(:id)
    p "===orders====#{orders}===="
    track = firebase.get("Transporter_#{transp_id}").body
    if track.present?
      firebase.update("Transporter_#{transp_id}",
                      "order" => orders)
    # 'l' => { '0' => lat , '1' => long }
    else
      firebase.set("Transporter_#{transp_id}",
                   "order" => orders,
                   "l" => { "0" => lat, "1" => long })
    end
  rescue StandardError => e
    p "====error====#{e}====="
  end

  def update_track_order(firebase, order)
    p "======order========#{order}======="
    transp_id = order.transporter_id
    orders = Order.find_orders_list(transp_id).pluck(:id).reject { |id| id == order.id }
    p "===orders====#{orders}===="
    firebase.update("Transporter_#{transp_id}",
                    "order" => orders)
    p "======transp_id========#{transp_id}======="
  rescue StandardError => e
    p "====error====#{e}====="
  end

  # def delete_driver_from_groups firebase,user_id,order_id
  #   firebase.delete("#{user_id}_Transporter_#{order_id}", :'.priority' => 1)
  # end

  def get_coverage_area(country_id, keyword)
    CoverageArea.get_all_coverage_area(country_id, keyword)
  end

  def get_coverage_area_web(keyword, page, per_page)
    CoverageArea.get_all_coverage_area_for_web(keyword, page, per_page)
  end

  def get_enable_restaurant_list(keyword, page, per_page)
    Restaurant.find_all_enable_list(keyword, page, per_page)
  end

  def add_suggest_restaurant(branch, description, area_id, user_id)
    SuggestRestaurant.create_suggest_restaurant(branch, description, area_id, user_id)
  end

  # def get_sort_and_filter keyword,area_id,rating,a_to_z,min_order_amount,fastest_delivery
  #   case keyword # a_variable is the variable we want to compare
  #   when "sort"    #compare to 1
  #        Branch.find_sorting_data(area_id,rating,a_to_z,min_order_amount,fastest_delivery)
  #   when "filter"   #compare to 2

  #   else

  #   end
  # end

  def coverage_area_json(area, user, language)
    area.as_json(logdinUser: user, language: language)
  end
end
