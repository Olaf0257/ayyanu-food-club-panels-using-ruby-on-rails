class Api::V1::PointsController < Api::ApiController
  before_action :authenticate_api_access
  before_action :check_expired_date

  def point_list
    pointList = get_user_point(@user, params[:page], params[:per_page], request.headers["language"])
    responce_json(code: 200, message: "Data fatech successfully!!", total_point: pointList[:totalPoint], ious: pointList[:point], currency_code_en: pointList[:currency_code_en], currency_code_ar: pointList[:currency_code_ar], total_pages: 1, point_count: 10)
  end

  def branch_wise_point_details
    points = get_branch_wise_point(params[:branch_id], @user, params[:page], params[:per_page])
    total_point = branch_available_point(@user.id, params[:branch_id])
    responce_json(code: 200, message: "Data fetched successfully!!", total_point: helpers.number_with_precision(total_point, precision: 3), points: points.as_json(only: [:id, :order_id, :user_point, :point_type, :created_at, :expired_date]))
  end

  def party_point_details
    user = User.find(params[:user_id])
    restaurant = Restaurant.find(params[:restaurant_id])
    points = get_influencer_selling_points(user, restaurant)
    total_point = points.sum(:party_point)
    responce_json(code: 200, message: "Data fetched successfully!!", total_point: helpers.number_with_precision(total_point, precision: 3), points: points.as_json(only: [:id, :order_id, :user_point, :party_point, :point_type, :created_at, :expired_date]))
  end

  def buy_party_points
    if @user
      seller = User.find(params[:user_id])
      restaurant = Restaurant.find(params[:restaurant_id])
      price = params[:selling_price]
      sold_points = params[:available_points]
      points = get_influencer_selling_points(seller, restaurant)
      sell_influencer_points(@user, points, price, params[:transaction_id])
      responce_json(code: 200, message: "Points added successfully!")
    else
      responce_json(code: 422, message: "Please Login")
    end
  end

  private

  def check_expired_date
    Point.where(expired_date: nil).each do |point|
      point.update(expired_date: (point.created_at + 6.months))
    end
  end
end
