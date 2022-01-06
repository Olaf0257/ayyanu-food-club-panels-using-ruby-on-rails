class Business::IousController < ApplicationController
  # include ActionController::Caching
  before_action :authenticate_business

  def iou_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"

    if restaurant && (@user.auths.first.role == "business")
      @branches = restaurant.branches
      @ious = get_branch_wise_iou(@branches, params[:branch], params[:keyword])

      respond_to do |format|
        format.html do
          @ious = @ious.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @ious.manage_ious_list_csv(@branch_name), filename: "manage_iou_list.csv" }
      end
    elsif @user.auths.first.role == "manager"
      @branches = @user.manager_branches
      @ious = get_branch_wise_iou(@branches, params[:branch], params[:keyword])

      respond_to do |format|
        format.html do
          @ious = @ious.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @ious.manage_ious_list_csv(@branch_name), filename: "manage_iou_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def business_paid_iou
    iou = find_iou(params[:iou_id])
    if iou
      order = find_order_id(iou.order.id)
      # expire_action :action => :iou_list

      if order.is_cancelled == true
        iou.update(is_received: true)
        send_json_response("Iou paid", "success", {})
      elsif order.is_delivered == true
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
end
