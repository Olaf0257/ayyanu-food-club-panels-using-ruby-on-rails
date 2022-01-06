class OrderMailer < ApplicationMailer
  def order_accept_mail(order)
    @order = order
    @items = []
    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end
    @email = order.user.email if order.user.present?
    mail(to: [@email], subject: "Your Order has been Accepted by restaurant")
  end

  def order_deliver_mail(order)
    @order = order
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = order.user.email if order.user.present?
    mail(to: [@email], subject: "Your Order Id #{order.id} has been Delivered")
  end

  def vat_order_deliver_mail(order)
    @order = order
    @email = order.user.email if order.user.present?
    mail(to: [@email], subject: "Delivery VAT Invoice for Order Id #{order.id}")
  end

  def order_reject_mail(order)
    @order = order
    @items = []
    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = order.user.email if order.user.present?
    mail(to: [@email], subject: "Your Order has been Rejected by restaurant")
  end

  def order_cancel_mail(order)
    @order = order
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    if order.user&.email.present?
      mail(to: order.user.email, subject: "Order Id #{order.id} is Cancelled")
    end
  end

  def payment_link_mail(user_id, redeem, address_id, note)
    @user = User.find(user_id)
    @redeem = redeem == "true"
    @address_id = address_id
    @note = note
    mail(to: @user.email, subject: "Food Club Order Payment Link")
  end

  def pending_order_mail(order)
    @order = order
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = order.branch.restaurant.user.email
    mail(to: @email, subject: "Order Pending Approval by Restaurant")
  end

  def admin_pending_order_mail(order)
    @order = order
    @branch = order.branch
    @restaurant = @branch.restaurant
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = SuperAdmin.first.email
    mail(to: @email, subject: "Order Pending Approval by Restaurant")
  end

  def admin_new_order_mail(order)
    @order = order
    @branch = order.branch
    @restaurant = @branch.restaurant
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = SuperAdmin.first.email
    mail(to: @email, subject: "New Order is Placed by #{order.user.name}")
  end

  def admin_cancel_order_mail(order)
    @order = order
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = SuperAdmin.first.email
    mail(to: @email, subject: "Order Id #{order.id} is Cancelled")
  end

  def driver_pending_order_mail(order, email)
    @order = order
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = email
    mail(to: @email, subject: "Order Pending to be Accepted by Driver")
  end

  def admin_driver_pending_order_mail(order)
    @order = order
    @company = @order.transporter.delivery_company
    @items = []

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = SuperAdmin.first.email
    mail(to: @email, subject: "Order Pending to be Accepted by Driver")
  end

  def late_order_mail(order, time)
    @order = order
    @items = []
    @time = time

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = order.branch.restaurant.user.email
    mail(to: @email, subject: "Late Order: #{time} mins")
  end

  def admin_late_order_mail(order, time)
    @order = order
    @branch = order.branch
    @restaurant = @branch.restaurant
    @items = []
    @time = time

    @order.order_items.each do |it|
      @items << "#{it.quantity} #{it.menu_item.item_name}"
    end

    @email = SuperAdmin.first.email
    mail(to: @email, subject: "Late Order: #{time} mins")
  end
end
