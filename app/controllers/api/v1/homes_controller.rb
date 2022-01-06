class Api::V1::HomesController < Api::ApiController
  before_action :authenticate_guest_access, except: [:web_suggest_restaurant]
  before_action :check_branch_status

  def home
    @data = home_page_data(params[:area_id], params[:image_width], params[:banner_img_width], @user, request.headers["language"])
    responce_json(code: 200, home_data: @data, cart_item_count: cart_item_counts)
  end

  def new_home
    @data = new_home_page_data(params[:area_id], params[:image_width], params[:banner_img_width], @user, request.headers["language"])
    responce_json(code: 200, cart_item_count: cart_item_counts, home_data: @data)
  end

  def suggest_search
    area = CoverageArea.find_by(id: params[:area_id])
    if area
      suggestSearch = get_suggest_search_data(area, request.headers["language"])
      responce_json(code: 200, data: suggestSearch, total_count: suggestSearch.count, category_count: suggestSearch.select { |i| i[:category] == "Collection" }.count, restaurant_count: suggestSearch.select{|i| i[:category] == "Restaurant" }.count)
    else
      responce_json(code: 404, msg: "Invalid Area!")
    end
  end

  def suggest_item_search
    area = CoverageArea.find_by(id: params[:area_id])
    if area
      suggestSearch = get_suggest_item_search_data(area, request.headers["language"])
      responce_json(code: 200, data: suggestSearch, total_count: suggestSearch.count, restaurant_count: suggestSearch.select { |i| i[:category] == "Restaurant" }.count, item_count: suggestSearch.select{|i| i[:category] == "Item" }.count)
    else
      responce_json(code: 404, msg: "Invalid Area!")
    end
  end

  def coverage_area
    if params[:country_id].present?
      @country_id = params[:country_id]
    elsif params[:latitude].present? && params[:longitude].present?
      address = Geocoder.search([params[:latitude], params[:longitude]]).first.data["address"]
      @country_id = address.present? ? Country.find_by(name: address["country"])&.id : nil
    end

    coverageArea = get_coverage_area(@country_id, params[:keyword])
    responce_json(code: 200, coverage_areas: coverage_area_json(coverageArea, @user, request.headers["language"]), total_pages: "1", coverage_area_count: coverageArea.count)
  end

  def check_coverage_area
    if params[:latitude].present? && params[:longitude].present?
      result = get_coverage_area_details(params[:latitude], params[:longitude])

      if result.present?
        coverage_area = CoverageArea.find_by(id: result[:area_id])
        responce_json(code: 200, area_name: coverage_area&.area.to_s, area_id: result[:area_id], country_id: result[:country_id], latitude: coverage_area&.latitude.to_s, longitude: coverage_area&.longitude.to_s)
      else
        responce_json(code: 404, message: "Please Enter Location")
      end
    else
      responce_json(code: 404, message: "Please Enter Location")
    end
  end

  def suggest_restaurant
    branch = get_branch(params[:branch_id])
    area = CoverageArea.find_by(id: params[:area_id])

    if branch && area
      suggestRestaurant = add_suggest_restaurant(branch, params[:description], params[:area_id], @user&.id)
      responce_json(code: 200, message: "Your suggestion have be submited.")
    else
      responce_json(code: 404, msg: "Invalid Area!")
    end
  end

  def web_suggest_restaurant
    branch = get_branch(params[:branch_id])
    area = CoverageArea.find_by(id: params[:area_id])
    user = User.find_by(id: params[:user_id])

    if branch && area
      if user
        user.suggest_restaurants.create(description: params[:description], restaurant_id: branch.restaurant.id, coverage_area_id: area.id)
      else
        SuggestRestaurant.create(description: params[:description], restaurant_id: branch.restaurant.id, coverage_area_id: area.id)
      end

      responce_json(code: 200, message: "Your suggestion has been submited.")
    else
      responce_json(code: 404, msg: "Invalid Area!")
    end
  end

  def create_requested_area
    country_id = Country.find_by(name: params[:country_name])&.id

    if country_id
      CoverageArea.create(area: params[:area_name], status: "deactivate", country_id: country_id, requested: true, location: params[:label], latitude: params[:latitude], longitude: params[:longitude])
      responce_json(code: 200, message: "Requested Area has been Created")
    else
      responce_json(code: 404, message: "Area cannot be Created")
    end
  end

  private

  def check_branch_status
    Branch.closing_restaurant
    Branch.open_restaurant
    BranchCoverageArea.closing_restaurant_area
    BranchCoverageArea.open_restaurant_area
  rescue ActiveRecord::StatementInvalid => e
  end
end
