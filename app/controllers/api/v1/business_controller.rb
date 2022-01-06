class Api::V1::BusinessController < Api::ApiController
  require "pusher"
  before_action :authenticate_api_access, except: [:branch_area]
  before_action :validate_business_role, except: [:branch_area]
  before_action :validate_adds_request_fields, only: [:adds_request]

  def iou_business_list
    iouList = get_iou_list(@user, params[:branch_id], params[:page], params[:per_page])
    responce_json(code: 200, message: "Data fatech successfully!!", ious: iou_list_data(iouList))
  end

  def paid_iou
    iou = find_iou(params[:iou_id])
    if iou
      order = find_order_id(iou.order.id)
      if order.is_delivered == true
        updateIou = iou.update(is_received: true)
        (updateIou == true) && (order.is_settled == false) ? order.update(is_settled: true, settled_at: DateTime.now) : ""
        send_json_response("Iou paid", "success", {})
      else
        send_json_response("Invalid order not delivered!!", "invalid", {})
      end
    else
      send_json_response("Invalid transporter", "invalid", {})
    end
  end

  def adds_request
    add = new_adds_request(params[:position], params[:place], params[:title], params[:description], params[:amount], params[:week_id], params[:branch_id], params[:coverage_area_id], params[:image])
    if add
      begin
        @webPusher = web_pusher(Rails.env)
        pusher_client = Pusher::Client.new(
          app_id: @webPusher[:app_id],
          key: @webPusher[:key],
          secret: @webPusher[:secret],
          cluster: "ap2",
          encrypted: true
        )
        pusher_client.trigger("my-channel", "my-event", {
                              })
      rescue Exception => e
      end
      send_json_response("Adds created successfully", "created", add: add)
    else
      send_json_response("Adds", "invalid", {})
    end
  end

  def adds_show
    adds = find_adds_req(params[:adds_id])
    adds ? send_json_response("Adds", "success", add: adds_show_json(adds)) : send_json_response("Invalid Adds!", "invalid", {})
  end

  def delete_adds
    add = find_adds_req(params[:adds_id])
    if add
      add.destroy
      send_json_response("Adds deleted successfully", "success", {})
    else
      send_json_response("Adds", "not exists", {})
    end
  end

  def week_list
    week = week_data(nil)
    send_json_response("Week List", "success", week: week.as_json)
  end

  def business_branches
    restaurant = get_restaurant_data(params[:restaurant_id])
    if restaurant
      branches = restaurant.branches
      send_json_response("Branch list", "success", branches: branch_json_data(branches))
    else
      send_json_response("Branch list", "not exists", {})
    end
  end

  def business_branch_areas
    branch = get_branch(params[:branch_id])
    branch ? send_json_response("Area list", "success", area: branch.coverage_areas.as_json) : send_json_response("Branch", "not exists", {})
  end

  def offers_list
    offers = find_business_offers(@user)
    offers ? send_json_response("Offer List", "success", offers: advertisement_status(offers)) : send_json_response("Invalid", "invalid", {})
  end

  def delete_offer
    offer = delete_business_offer(params[:offer_id], @user)
    offer[:status] ? send_json_response("Offer deleted successfully", "success", {}) : send_json_response("Invalid Offer", "invalid", {})
  end

  def branch_area
    branch = get_branch(params[:branch_id])
    if branch
      areas = branch.branch_coverage_areas
      dbArea = []
      areas.each do |ar|
        area = {}
        area["area"] = ar.coverage_area.area
        area["coverage_area_id"] = ar.coverage_area_id
        dbArea << area
        dbArea
      end
      responce_json(code: 200, message: "Data fatech successfully!!", areas: dbArea)
    else
      responce_json(code: 422, errors: "Invalid branch!!")
    end
  end

  def reload_business_restaurants
    responce_json(code: 200, user: business_user_login_json(@user).merge(api_key: request.headers["HTTP_ACCESSTOKEN"], role: "business"))
  end

  private

  def validate_business_role
    role = get_user_auth(@user, "business")
    unless role
      responce_json(code: 422, errors: "Invalid user!!")
    end
  end

  def validate_adds_request_fields
    week = find_week(params[:week_id])
    branch = get_branch(params[:branch_id])
    coverage_area = find_area(params[:coverage_area_id])
    unless week.present? && branch.present? && coverage_area.present?
      responce_json(code: 422, errors: "Invalid week or branch or coverage_area")
    end
  end
end
