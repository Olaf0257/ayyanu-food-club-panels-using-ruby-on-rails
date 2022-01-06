class Customer::PointsController < ApplicationController
  before_action :authenticate_customer
  before_action :check_point_expired_date

  def party_points_list
    country_id = session[:country_id].presence || 15
    result = Point.sellable_restaurant_wise_points(country_id)
    @data = party_category_json(result, @user, request.headers["language"])
  end

  def party_points_details
    @influencer = User.find(params[:user_id])
    @restaurant = Restaurant.find(params[:restaurant_id])
    @points = get_influencer_selling_points(@influencer, @restaurant)
    @total_point = helpers.number_with_precision(@points.sum(:party_point), precision: 3)
    @points = @points.as_json(only: [:id, :order_id, :user_point, :party_point, :point_type, :created_at, :expired_date])
  end

  def buy_party_points
    @charge_id = params[:tap_id]
    url = URI("https://api.tap.company/v2/charges/#{@charge_id}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
    request.body = "{}"

    response = http.request(request)
    data = JSON.parse(response.read_body)

    if data["status"] != "CAPTURED"
      flash[:error] = "TRANSACTION " + data["status"].to_s
    else
      seller = User.find(params[:seller_id])
      buyer = User.find(params[:buyer_id])
      restaurant = Restaurant.find(params[:restaurant_id])
      price = params[:selling_price]
      sold_points = params[:available_points]
      points = get_influencer_selling_points(seller, restaurant)
      sell_influencer_points(buyer, points, price, @charge_id)
      flash[:success] = "Successfully Bought Party Points"
    end

    redirect_to customer_party_points_list_path
  end

  private

  def check_point_expired_date
    Point.where(expired_date: nil).each do |point|
      point.update(expired_date: (point.created_at + 6.months))
    end
  end
end