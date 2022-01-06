class Api::V1::TransportersController < Api::ApiController
  before_action :authenticate_api_access
  before_action :validate_user_role, only: [:transporter_tracking]

  def transporter_tracking
    user = get_user_lat_log(params[:latitude], params[:longitude], @user)
    responce_json(code: 200, message: "Update latitude and  longitude successfully", user: user_login_json(@user).merge(api_key: request.headers["accessToken"]))
  end

  def transporter_status
    user = @user.auths.first.role == "transporter" ? update_active_status(@user) : false
    user == false ? responce_json(code: 200, errors: "Invalid role!!") : responce_json(code: 200, status: @user.status)
  end

  def transpoter_iou_list
    iouList = get_transpoter_iou_list(@user, params[:page], params[:per_page])
    responce_json(code: 200, message: "Data fatech successfully!!", ious: iou_list_json(iouList))
  end

  def zone_list
    if @user.delivery_company.present?
      zones = @user.zones.presence || @user.delivery_company.zones.presence || Zone.joins(district: :state).where(states: { country_id: @user.delivery_company.country_id }).distinct
      responce_json(code: 200, zone_list: zones.as_json(language: request.headers["language"]))
    else
      responce_json(code: 200, zone_list: [{ "id": nil, "zone_name": "All Zones" }])
    end
  end

  def zone_area_list
    zone_id = params[:zone_id]

    if zone_id.present?
      areas = Zone.find_by(id: zone_id)&.coverage_areas&.active_areas&.order(:area)
      responce_json(code: 200, area_list: areas.as_json(language: request.headers["language"]))
    else
      responce_json(code: 422, errors: "Invalid zone")
    end
  end

  def shifts_list
    shifts = @user.delivery_company_shifts.order(:day, :start_time)
    responce_json(code: 200, shifts_list: shifts.as_json)
  end

  def accept_order
    order = Order.find_by(id: params[:order_id])

    if order
      order.update(driver_accepted_at: DateTime.now)
      OrderDriver.where(order_id: order.id, transporter_id: @user.id).last&.update(driver_accepted_at: DateTime.now) if @user
      responce_json(code: 200, message: "Order Accepted!")
    else
      responce_json(code: 422, errors: "Invalid order")
    end
  end

  private

  def validate_user_role
    user = get_user_auth(@user, "transporter")
    unless user
      responce_json(code: 422, errors: "Invalid user!!")
    end
  end
end
