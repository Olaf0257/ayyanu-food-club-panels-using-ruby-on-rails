module Api::V1::RestaurantsHelper
  def categories_except_attributes
    { except: [:created_at, :updated_at, :image] }
  end

  def restaurant_except_attributes
    { except: [:created_at, :updated_at, :id, :user_id] }
  end

  def branches_except_attributes
    { except: [:created_at, :updated_at] }
  end

  def favorite_branches_except_attributes
    { except: [:created_at, :updated_at], methods: [:restaurant_name, :restaurant_logo, :image, :average_ratings, :discount, :delivery_time, :categories, :image_thumb, :currency_code_en, :currency_code_ar, :coverage_area] }
  end

  def branche_menu_item_except_attributes
    { except: [:created_at, :updated_at, :item_rating, :price_per_item, :item_description, :menu_category_id, :is_available], methods: [:after_discount_amount] }
  end

  def restaurant_json(restaurants, language, area_id)
    restaurants.as_json(language: language, areaWies: area_id, only: [:id, :min_order_amount, :accept_cash, :accept_card, :delivery_charges])
  end

  def reviews_json(reviews)
    reviews.as_json(include: [user: { only: [:name] }])
  end

  def web_restaurant_branch_json(branches)
    branches.as_json(only: [:id, :address])
  end

  def menu_json(menu_items, language, branch)
    menu_items.as_json(language: language, branch: branch)
  end

  def get_restaurant_branch(branch_id)
    Branch.find_branch(branch_id)
  end

  def restaurant_rating_by_id(rating_id)
    Rating.find_by(id: rating_id)
  end

  def get_restaurant_order_rating(order_rating_id)
    OrderReview.find_by(id: order_rating_id)
  end

  def get_menu_item(item_id)
    MenuItem.find_menu_item(item_id)
  end

  def get_branch_menu_item(branch, item_id)
    MenuItem.find_brach_menu_item(branch, item_id)
  end

  # def get_menu_item_addons item
  # end

  def get_cart_menu_item(user, item_id)
    if user
      cart = user.cart
      items = if cart
                cart_list_json(cartItemsByItemId(cart, item_id))
              else
                []
              end
    else
      cart = Cart.find_by(guest_token: @guestToken)
      items = if cart
                cart_list_json(cartItemsByItemId(cart, item_id))
              else
                []
              end
    end
    items
  end

  def cartItemsByItemId(cart, item_id)
    CartItem.find_cart_menu_item(cart, item_id)
  end

  def get_branch_menu_list(user, guestToken, branch, image_width, language, item_ids, area_id, keyword)
    cat = []
    area = branch.branch_coverage_areas.find_by(coverage_area_id: area_id)
    categories = Branch.find_branch_menu(branch)

    categories.where(available: true, approve: true).each do |category|
      all_items = category.menu_items
      all_items = all_items.where("item_name like ?", "%#{ keyword.squish }%") if keyword.present?
      next if all_items.select { |i| i.price_per_item.positive? || (i.price_per_item.zero? && i.item_addon_categories.joins(:item_addons).where(item_addon_categories: { approve: true }, item_addons: { approve: true }).present?) }.select { |i| i.far_menu == true || area&.far_menu == false }.blank?

      menu_items = category_json(category, image_width, branch, user, guestToken, language, item_ids, area, keyword)

      if menu_items[:items].present?
        cat << menu_items
      end
    end

    cat
  end

  def get_branch_menu_categories(branch, area_id)
    area = branch.branch_coverage_areas.find_by(coverage_area_id: area_id)
    categories = branch.menu_categories.includes(:menu_items).joins(:menu_items).where("menu_categories.available = true AND menu_categories.id IS NOT NULL and menu_categories.approve = ? and menu_category_id IS NOT NULL and menu_items.approve = ? and menu_items.is_available = (?) and ((DATE(start_date) IS NULL or TIME(end_time) IS NULL) or (DATE(start_date) <= ? and DATE(end_date) >= ? and start_time <= ? and end_time > ?))", true, true, true, Date.today, Date.today, Time.now, Time.now).order(:category_priority, :category_title).uniq

    daily_dishes = MenuCategory.find_by(id: categories.select { |c| c.category_title == "Daily Dishes" }.last&.id)

    if daily_dishes
      categories -= [daily_dishes]
      daily_dishes_items = daily_dishes.menu_items.joins(:menu_item_dates).where("Date(menu_date) = ?", Date.today)
      categories += [daily_dishes] if daily_dishes_items.present?
    end

    categories = categories.select { |c| c.menu_items.select { |i| i.price_per_item.positive? || (i.price_per_item.zero? && i.item_addon_categories.joins(:item_addons).where(item_addon_categories: { approve: true }, item_addons: { approve: true }).present?) }.select { |i| i.far_menu == true || area&.far_menu == false }.present? }.sort_by { |c| [c.category_priority, c.category_title] }
  end

  def category_json(category, image_width, branch, user, guestToken, language, _item_ids, area, keyword)
    all_items = category.menu_items
    all_items = all_items.where("item_name like ?", "%#{ keyword.squish }%") if keyword.present?

    if category.category_title == "Daily Dishes"
      category.as_json(user: user, language: language).merge(items: all_items.joins(:menu_item_dates).where("approve = ? and is_available = ? and DATE(menu_date) = ?", true, true, Date.today)
      .select { |i| i.price_per_item.positive? || (i.price_per_item.zero? && i.item_addon_categories.joins(:item_addons).where(item_addon_categories: { approve: true, available: true }, item_addons: { approve: true, available: true }).present?) }.select { |i| i.far_menu == true || area&.far_menu == false }
      .as_json(imgWidth: image_width, logdinUser: user, guestToken: guestToken, language: language, branch: branch))
    else
      category.as_json(user: user, language: language).merge(items: all_items.where("approve = ? and is_available = ?", true, true)
      .select { |i| i.price_per_item.positive? || (i.price_per_item.zero? && i.item_addon_categories.joins(:item_addons).where(item_addon_categories: { approve: true, available: true }, item_addons: { approve: true, available: true }).present?) }.select { |i| i.far_menu == true || area&.far_menu == false }
      .as_json(imgWidth: image_width, logdinUser: user, guestToken: guestToken, language: language, branch: branch))
    end
  end

  def get_daily_dishes_data(branch)
    branch.menu_categories.joins(:menu_items).where("menu_categories.available = true AND menu_categories.id IS NOT NULL and menu_categories.approve = ? and menu_category_id IS NOT NULL and menu_items.approve = ? and menu_items.is_available = (?) and start_time <= ? and end_time > ?", true, true, true, Time.now, Time.now).includes(menu_items: [{ item_addon_categories: :item_addons }]).where(approve: true).first
  end

  def get_business_branch_menu_list(user, guestToken, branch, image_width, language, keyword, category)
    cat = []
    branch_categories = Branch.find_branch_menu_for_business(branch)
    daily_dishes = branch.menu_categories.includes(menu_items: [{ item_addon_categories: :item_addons }]).where(category_title: "Daily Dishes").first
    cat << business_category_json(daily_dishes, image_width, user, guestToken, language, keyword) if daily_dishes.present?
    categories = if keyword.present?
                   branch_categories.where("category_title like (?)", "%#{category}%")
                 else
                   branch_categories.includes(menu_items: [{ item_addon_categories: :item_addons }])
                 end
    categories.each do |category|
      cat << business_category_json(category, image_width, user, guestToken, language, keyword)
    end
    cat
  end

  def branch_menu_category(branch, keyword, _category)
    if keyword.present?
      Branch.find_branch_menu_for_business(branch).where("category_title like (?)", "%#{keyword}%").lock(false)
    else
      branch_categories = Branch.find_branch_menu_for_business(branch).lock(false)
    end
  end

  def branch_menu_item(branch, menu_categories, keyword, category)
    if keyword.present?
      category = Branch.find_branch_menu_for_business(branch)
      MenuItem.includes(:menu_category, :item_addon_categories).where("menu_category_id IN (?) and item_name like ?", category.pluck(:id), "%#{keyword}%").lock(false)
    else
      MenuItem.includes(:menu_category, :item_addon_categories).where("menu_category_id IN (?)", menu_categories.pluck(:id)).lock(false)
    end
  end

  def branch_addon_category(branch, keyword, _category)
    if keyword.present?
      branch.item_addon_categories.where("addon_category_name like ?", "%#{keyword}%")
    else
      branch.item_addon_categories
    end
  end

  def branch_addon_item(branch, addon_categories, keyword, _category)
    if keyword.present?
      categories = branch.item_addon_categories
      ItemAddon.where("item_addon_category_id IN (?) and addon_title like (?)", categories.pluck(:id), "%#{keyword}%")
    else
      ItemAddon.where("item_addon_category_id IN (?)", addon_categories.pluck(:id))
    end
  end

  def business_category_json(category, image_width, user, guestToken, language, keyword)
    if keyword.present?
      category.as_json(user: user, language: language).merge(items: category.menu_items.where("item_name like (?)", "%#{keyword}%").includes(item_addon_categories: :item_addons).as_json(imgWidth: image_width, logdinUser: user, guestToken: guestToken, language: language))
    else
      category.as_json(includes: [menu_items: [{ item_addon_categories: :item_addons }]]).merge(items: category.menu_items.includes(item_addon_categories: :item_addons).as_json(imgWidth: image_width, logdinUser: user, guestToken: guestToken, language: language))
    end
  end

  def get_addon_item_list(item, user, language)
    addonItem = []
    addonCategories = item.item_addon_categories

    addonCategories.where(approve: true, available: true).each do |addon|
      if addon.item_addons.where(approve: true, available: true).present?
        addonItem << addon_json(addon, user, language, item)
      end
    end
    addonItem
  end

  def addon_json(addon, user, language, item)
    addon.as_json(logdinUser: user, language: language, item: item).merge(addon_items: addon.item_addons.where(approve: true, available: true).as_json(logdinUser: user, language: language))
  end

  def get_cart_item(_user, _cart_item_id)
    CartItem.find_cart_item
  end

  def get_restaurant_list(page, per_page)
    Restaurant.find_restaurant_list("", page, per_page, "")
  end

  def user_restaurant_login(login_id)
    User.joins(:restaurants).where("restaurants.login_id = ?", login_id).first
  end

  def branches_by_location(searchkey, latitude, longitude, page, per_page)
    if longitude.present? && longitude.present?
      branch = Branch.near([latitude, longitude], 50).paginate(page: page, per_page: per_page)
      suggest_search_json(branch)
    elsif searchkey.present?
      branch = Branch.where("address  LIKE (?)", searchkey).paginate(page: page, per_page: per_page)
      suggest_search_json(branch)
    elsif searchkey.present? && longitude.present? && longitude.present?
      branch = Branch.near([latitude, longitude], 50).where("address  LIKE ", searchkey).paginate(page: page, per_page: per_page)
      suggest_search_json(branch)
    else
      branch = Branch.where("address  LIKE (?)", searchkey).paginate(page: page, per_page: per_page)
      suggest_search_json(branch)
    end
  end

  def search_branches(area, searchkey)
    area.branches.joins(:restaurant).where("restaurants.title  LIKE ? and restaurants.is_signed = (?) and branches.is_approved = ? and branches.is_closed = ?", "%#{searchkey}%", true, true, false).includes(:restaurant, :branch_coverage_areas).distinct
  end

  def search_polling_branches(area, searchkey, page, per_page)
    area.branches.joins(:restaurant).where("restaurants.title  LIKE ? and restaurants.is_signed = (?) and branches.is_approved = ? and branches.is_closed = ?", "%#{searchkey}%", true, false, false).includes(:restaurant, :branch_coverage_areas).distinct.paginate(page: page, per_page: per_page)
  end

  def search_branches_without_area(area, searchkey, page, per_page)
    existing_restaurant_ids = search_branches(area, searchkey).pluck(:restaurant_id)
    Branch.joins(:restaurant, :coverage_areas).where("restaurants.title  LIKE ? and (restaurants.is_signed = (?) and coverage_areas.id != ? and coverage_areas.country_id = ? and branches.is_closed = ?)", "%#{searchkey}%", true, area.id, area.country_id, false).includes(:restaurant, :branch_coverage_areas).distinct.where.not(restaurant_id: existing_restaurant_ids).paginate(page: page, per_page: per_page)
  end

  def search_category(area, searchkey)
    Category.joins(branches: [:coverage_areas]).where("coverage_areas.id=? and title  LIKE ?", area.id, "%#{searchkey}%").distinct
  end

  def search_menu_item(branch_ids, area, searchkey, page, per_page)
    items = MenuItem.joins(menu_category: { branch: [:restaurant, :coverage_areas] }).where("coverage_areas.id = ? and restaurants.is_signed = (?) and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?) and menu_items.item_name like ?", area.id, true, true, true, true, true, "%#{searchkey}%").order("avg_rating DESC, restaurants.title")
    items = items.where(branches: { id: branch_ids }) if branch_ids
    items = items.distinct.includes(:item_addon_categories, menu_category: { branch: :restaurant }).paginate(page: page, per_page: per_page)
    items
  end

  def branches_by_category(category_id, page, per_page)
    branch = Branch.joins(:categories).where("categories.id = ? ", category_id).distinct.paginate(page: page, per_page: per_page)
    suggest_search_json(branch)
   end

  def branches_by_restaurant(rest_id, _page, _per_page)
    branch = Branch.where("restaurant_id = ?", rest_id) # .paginate(:page =>page,:per_page => per_page)
    suggest_search_json(branch)
    end

  # test method for

  def add_transporter(branch_id, user_id)
    BranchTransport.created_branch_transporter(branch_id, user_id)
  end

  def get_business_transporter(branch_id, user_id)
    BranchTransport.find_by(user_id: branch_id, branch_id: user_id)
  end

  # def add_transporter_iou user,order_id,transporter_id,amount
  #   Iou.create_iou(user,order_id,transporter_id,amount)
  # end

  def add_new_category(title, image)
    url = upload_multipart_image(image, "categories")
    Category.create_category(title, url)
  end

  def get_category_details(category_id)
    Category.find_by(id: category_id)
  end

  def update_category_info(category, title, uploadImage, color)
    Category.update_category_details(category, title, uploadImage, color)
  end

  def get_branch_ratings(branch)
    reviews = branch.ratings
    count = reviews.count

    over_all = reviews.pluck(:rating).map(&:to_f).sum.round(1)
    food_quantity = reviews.pluck(:food_quantity_rating).map(&:to_f).sum.round(1)
    food_taste = reviews.pluck(:food_taste_rating).map(&:to_f).sum.round(1)
    value = reviews.pluck(:value_rating).map(&:to_f).sum.round(1)
    packaging = reviews.pluck(:packaging_rating).map(&:to_f).sum.round(1)
    seal = reviews.pluck(:seal_rating).map(&:to_f).sum.round(1)

    over_all_rate = over_all.positive? ? (over_all.to_f / count) : 0
    food_quantity_rate = food_quantity.positive? ? (food_quantity.to_f / count) : 0
    food_taste_rate = food_taste.positive? ? (food_taste.to_f / count) : 0
    value_rate = value.positive? ? (value.to_f / count) : 0
    packaging_rate = packaging.positive? ? (packaging.to_f / count) : 0
    seal_rate = seal.positive? ? (seal.to_f / count) : 0

    { food_quantity_rate: helpers.number_with_precision(food_quantity_rate, precision: 1).to_f,
      food_taste_rate: helpers.number_with_precision(food_taste_rate, precision: 1).to_f,
      value_rate: helpers.number_with_precision(value_rate, precision: 1).to_f,
      packaging_rate: helpers.number_with_precision(packaging_rate, precision: 1).to_f,
      seal_rate: helpers.number_with_precision(seal_rate, precision: 1).to_f,
      over_all_review: helpers.number_with_precision(over_all_rate, precision: 1).to_f,
      rate_count: count,
      packing_rate: "",
      value_for_money_rate: "",
      delivery_time_rate: "",
      quality_of_food_rate: "",
      driver_rate: "" }
  end
end
