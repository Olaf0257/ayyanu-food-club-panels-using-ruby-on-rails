class RestaurantMailer < ApplicationMailer
  def send_email_on_restaurant_owner_with_loginId(email, owner_name, password)
    @email = email
    @user_name = owner_name
    @password = password
    mail(to: @email, subject: "Food Club join")
  end

  def send_email_to_restaurant(restaurant)
    @email = restaurant.email
    @user_name = restaurant.owner_name
    @resion = restaurant.reject_reason
    mail(to: @email, subject: "Food Club")
  end

  def send_email_restaurant_doc_reject(doc)
    @email = doc.restaurant.user.email
    @user_name = doc.restaurant.user.name
    @resion = doc.reject_reason
    mail(to: @email, subject: "Food Club")
  end

  def send_email_restaurant_doc_approved(doc)
    @email = doc.restaurant.user.email
    @user_name = doc.restaurant.user.name
    @resion = doc.reject_reason
    mail(to: @email, subject: "Food Club")
  end

  def send_email_on_restaurant_owner_with_area_status(email, area)
    @email = email
    @area = area.coverage_area.area
    if (area.is_closed == true) && (area.is_busy == true)
      @statu = "Area Close"
    elsif area.is_busy == true
      @statu = "Area Busy"
    elsif area.is_closed == true
      @statu = "Area Close"
    elsif (area.is_closed == false) && (area.is_busy == false)
      @status = "Area Open Now"
    end
    @status = @status.presence || "Area Open Now"
    # mail( :to => @email, :subject => 'Food Club' )
  end

  def send_email_to_admin_new_branch(restaurant, admin)
    @email = admin.email
    @restaurant_name = restaurant.title
    mail(to: @email, subject: "Food Club")
  end

  def send_offer_email_restaurant(restaurant, _offer)
    @email = restaurant.user.email
    @restaurant_name = restaurant.title
    # @menu_name  = offer.menu_item.item_name
    mail(to: @email, subject: "Food Club")
  end

  def event_reminder_mail(restaurant_id, event_date_id)
    @restaurant = Restaurant.find_by(id: restaurant_id)
    @event_date = EventDate.find(event_date_id)
    @event = @event_date.event
    @email = @restaurant ? @restaurant.user.email : SuperAdmin.first.email
    mail(to: @email, subject: "Food Club Event Reminder")
  end

  def order_summary_report_mail(branch_id, order_ids, refund_order_ids)
    @branch = Branch.find_by(id: branch_id)
    @restaurant = @branch.restaurant
    @email = @restaurant.user.email
    @orders = Order.where(id: order_ids)
    @refund_orders = Order.where(id: refund_order_ids)
    mail(to: @email, cc: SuperAdmin.first.email, subject: "Food Club Order Summary Report")
  end

  def tax_invoice_mail(branch_id, order_ids)
    @branch = Branch.find_by(id: branch_id)
    @restaurant = @branch.restaurant
    @email = @restaurant.user.email
    @orders = Order.where(id: order_ids)
    mail(to: @email, cc: SuperAdmin.first.email, subject: "Food Club Tax Invoice")
  end
end
