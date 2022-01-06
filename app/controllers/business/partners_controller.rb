class Business::PartnersController < ApplicationController
  before_action :authenticate_business, only: [:enterprise_dashboard, :dashboard, :pos_dashboard, :pos_new_transaction, :manager_dashboard, :kitchen_manager_dashboard, :manual_order, :create_manual_order, :requested_orders_list, :area_details, :kds_menu, :kds_color_setting, :find_branches_based_country, :pos_no_of_table, :pos_dashboard_terminal, :pos_payment]
  before_action :check_branch_status, only: [:dashboard, :pos_dashboard, :pos_new_transaction, :manager_dashboard, :kitchen_manager_dashboard, :kds_menu, :kds_color_setting]

  def login
    render layout: "blank"
  end

  def partner_auth
    if params[:email].present? && params[:password].present?
      userdata = User.find_by(email: params[:email])
      user = userdata ? userdata : user_restaurant_login(params[:email])

      if user
        @auth = user.auths.where("role = ? or role = ? or role = ? or role = ?", "business", "manager", "kitchen_manager", "delivery_company").first
        @auth ||= user.auths.find_by(role: "customer") if user.influencer
        session[:partner_user_id] = nil if session[:partner_user_id].present?

        if user && (@auth ? @auth.valid_password?(params[:password]) : false)
          server_session = @auth.server_sessions.create(server_token: @auth.ensure_authentication_token)
          session[:partner_user_id] = server_session.server_token

          if @auth.role == "business"
            if @auth.user.enterprise
              redirect_to business_enterprise_dashboard_path(enterprise_id: encode_token(@auth.user.enterprise.id))
            else
              redirect_to business_partner_dashboard_path(restaurant_id: encode_token(user.restaurants.first.id))
            end
          elsif @auth.role == "manager"
            # redirect_to business_manager_dashboard_path
            redirect_to dashboard_business_enterprises_path(enterprise: true)
          elsif @auth.role == "delivery_company"
            redirect_to delivery_company_dashboard_path
          elsif user.influencer && @auth.role == "customer"
            redirect_to influencer_dashboard_path
          else
            redirect_to business_kitchen_manager_dashboard_path(restaurant_id: encode_token(user.branch_kitchen_managers.first.branch.restaurant.id))
          end
        else
          flash[:error] = "Unauthorised Access !!"
          redirect_to business_partner_login_path
        end
      else
        flash[:error] = "Unauthorised Access !!"
        redirect_to business_partner_login_path
      end
    else
      flash[:error] = "Email and password can't be blank"
      redirect_to business_partner_login_path
    end
  end

  def dashboard
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @title = restaurant.title
      @restaurants = @user.restaurants
      @branches = restaurant.branches
      @busyCount = @branches.where(is_busy: true).count
      @transporters = get_transporters(restaurant)
      @managers = get_managers(restaurant)
      @restaurant_id = params[:restaurant_id]
      @busy = get_business_busy_restaurant_by_business(decode_token(@restaurant_id))
      @close = get_business_close_restaurant_by_business(decode_token(@restaurant_id))
      @orders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?) and orders.is_cancelled = ?", restaurant, true, false, true, true, true, true, false).lock(false)
      @newOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and is_accepted = (?) and is_rejected = (?) and orders.is_cancelled = ?", restaurant, Date.today, false, false, false).lock(false).order("id DESC")
      @punchedOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and ((is_accepted = (?) and is_rejected = (?)) or is_ready = (?) or pickedup = (?) or is_delivered = (?)) and is_settled = (?) and orders.is_cancelled = ?", restaurant, Date.today, true, false, true, true, true, false, false).lock(false).order("id DESC")
      @keyword = params[:keyword].presence || "day"
      @earningGraphData = business_earning_graphdata(@keyword, restaurant)
      respond_to do |format|
        if params[:fc_panel] == "true"
          format.html { render layout: "partner_application" }
        else
          format.html { redirect_to dashboard_business_enterprises_path(restaurant_id: params[:restaurant_id]) }
        end
        format.js { render "index", locals: { :@branches => @branches, :@transporters => @transporters, :@managers => @managers, :@orders => @orders, :@newOrders => @newOrders, :@punchedOrders => @punchedOrders, :@restaurant_id => encode_token(restaurant.id) } }
      end
    else
      redirect_to_root
    end
  end

  def enterprise_dashboard
    # restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    restaurant = Enterprise.find_by_id(decode_token(params[:enterprise_id]))

    if restaurant
      @title = restaurant.enterprise_name
      # @restaurants = @user.restaurants
      @branches = restaurant.branches rescue []
      @busyCount = @branches.where(is_busy: true).count  rescue []
      @transporters = get_transporters(restaurant)  rescue []
      @managers = get_managers(restaurant)  rescue []
      @restaurant_id = params[:enterprise_id]  rescue []
      @busy = get_business_busy_restaurant_by_business(decode_token(@restaurant_id))
      @close = get_business_close_restaurant_by_business(decode_token(@restaurant_id))
      @orders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?) and orders.is_cancelled = ?", restaurant, true, false, true, true, true, true, false).lock(false)
      @newOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and is_accepted = (?) and is_rejected = (?) and orders.is_cancelled = ?", restaurant, Date.today, false, false, false).lock(false).order("id DESC")
      @punchedOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and ((is_accepted = (?) and is_rejected = (?)) or is_ready = (?) or pickedup = (?) or is_delivered = (?)) and is_settled = (?) and orders.is_cancelled = ?", restaurant, Date.today, true, false, true, true, true, false, false).lock(false).order("id DESC")
      @keyword = params[:keyword].presence || "day"
      @earningGraphData = business_earning_graphdata(@keyword, restaurant)

      respond_to do |format|
        format.html { render layout: "partner_application" }
        format.js { render "index", locals: { :@branches => @branches, :@transporters => @transporters, :@managers => @managers, :@orders => @orders, :@newOrders => @newOrders, :@punchedOrders => @punchedOrders, :@restaurant_id => encode_token(restaurant.id) } }
      end
    else
      redirect_to_root
    end
  end

  def manager_dashboard
    # begin
    @branches = @user.branch_managers
    @manager_branch = @user.manager_branches.first
    @branch_coverage_areas = @manager_branch.branch_coverage_areas
    branch = @branches.pluck(:branch_id)
    @busyCount = get_manager_branch_list(@user).where(is_busy: true).count
    @transporters = get_transporters("")
    @managers = get_managers("")
    @busy = get_manager_busy_restaurant_by_partner(branch)
    @close = get_manager_close_restaurant_by_partner(branch)
    @orders = Order.where("branch_id in (?) and is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?) and orders.is_cancelled = ?", branch, true, false, true, true, true, true, false)
    @newOrders = Order.includes(:branch).where("branch_id in (?) and DATE(orders.created_at) = (?) and is_accepted = (?) and is_rejected = (?) and orders.is_cancelled = ?", branch, Date.today, false, false, false).order("id DESC")
    @punchedOrders = Order.includes(:branch).where("branch_id in (?) and DATE(orders.created_at) = (?) and ((is_accepted = (?) and is_rejected = (?)) or is_ready = (?) or pickedup = (?) or is_delivered = (?)) and is_settled = (?) and orders.is_cancelled = ?", branch, Date.today, true, false, true, true, true, false, false).order("id DESC")
    respond_to do |format|
      format.html { render layout: "partner_application" }
      # format.html { redirect_to dashboard_business_enterprises_path }
      format.js { render "manager_index", locals: { :@branches => @branches, :@transporters => @transporters, :@managers => @managers, :@orders => @orders, :@newOrders => @newOrders, :@punchedOrders => @punchedOrders } }
    end
    # rescue Exception => e
    #   redirect_to_root()
    # end
  end

  def kitchen_manager_dashboard
    @orders = Order.where(is_cancelled: false).where("branch_id = ? and DATE(orders.created_at) = (?) and is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?)  and DATE(cooked_at) = ? or (branch_id = ? and DATE(orders.created_at) = (?) and is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and DATE(cooked_at) = ?)", @user.branch_kitchen_managers.first.branch.id, Date.today, true, false, false, false, false, Date.today, @user.branch_kitchen_managers.first.branch.id, Date.today, true, false, true, false, false, Date.today).paginate(page: params[:page], per_page: params[:per_page])
    render layout: "partner_application"
  end

  def pos_new_check
    branch = Branch.find_by(id: params[:branch_id])
    if branch.present?
      pos_check = branch.pos_checks.create(no_of_guest: '', order_type_id: params[:selected_order_type])
      if params[:selected_order_type].present?
        render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(branch.restaurant_id), :table => 'no_table', check: encode_token(pos_check.id))}'"
      else
        redirect_to business_partner_pos_new_transaction_path(restaurant_id: encode_token(branch.restaurant_id), :table => 'no_table', check: encode_token(pos_check.id))
      end
    end
  end

  def quick_pay_popup
    restaurant = Restaurant.find_by id: decode_token(params[:restaurant_id])
    if restaurant.present?
      @tax = Tax.where(country_id: restaurant.country_id).pluck(:percentage).sum
      @pos_checks = restaurant.branches.map { |branch| branch.pos_checks.where(is_new_merged: false, check_status: 'saved') }.flatten.compact.uniq
    else
      render :js => "Restaurant not found"
    end
  end

  def apply_coupon_code
    coupon_code = params[:coupon_code]
    branch = Branch.find_by id: params[:branch_id]
    @pos_check = PosCheck.find_by id: params[:pos_check_id_coupon]
    @isAlreadyApplied = false
    @tax = Tax.where(country_id: branch&.restaurant&.country_id).pluck(:percentage).sum
    if @pos_check.pos_payments.where(pending_delete: false).pluck(:payment_method_id).count(4) == 0
      @applied_coupon = branch.influencer_coupons.find_by("DATE(start_date) <= ? AND DATE(end_date) >= ? && coupon_code = ?", Date.today.to_date, Date.today.to_date, coupon_code)
      @applied_coupon = InfluencerCoupon.find_by("DATE(start_date) <= ? AND DATE(end_date) >= ? && coupon_code = ?", Date.today.to_date, Date.today.to_date, coupon_code) unless @applied_coupon.present?
      @applied_coupon = (!@applied_coupon&.branches.present? || (@applied_coupon&.branches.present? && @applied_coupon&.branch_ids&.include?(@pos_check.branch_id))) ? @applied_coupon : nil
      @restaurant_coupon = branch.restaurant_coupons.find_by("DATE(start_date) <= ? AND DATE(end_date) >= ? && coupon_code = ?", Date.today.to_date, Date.today.to_date, coupon_code)
      @restaurant_coupon = RestaurantCoupon.find_by("DATE(start_date) <= ? AND DATE(end_date) >= ? && coupon_code = ?", Date.today.to_date, Date.today.to_date, coupon_code) unless @restaurant_coupon.present?
      @restaurant_coupon = (!@restaurant_coupon&.branches.present? || (@restaurant_coupon&.branches.present? && @restaurant_coupon&.branch_ids&.include?(@pos_check.branch_id))) ? @restaurant_coupon : nil

      if @restaurant_coupon.present?
        @pos_payments = PosPayment.where(coupon_code: @restaurant_coupon.coupon_code)
        if @pos_payments.count < @restaurant_coupon.total_quantity
          if @restaurant_coupon.menu_item_ids.present?
            pos_menu_list = @pos_check.pos_transactions.where(itemable_type: "MenuItem")
            discounted_menu_item = pos_menu_list.map { |menu| menu if @restaurant_coupon.menu_items.pluck(:id).include?(menu.itemable_id) }.flatten.uniq.compact
            if discounted_menu_item.present?
              @restaurant_coupon.update quantity: (@restaurant_coupon.quantity-1) 
              discount_amount = ((before_tax_amount(@tax, discounted_menu_item.map(&:total_amount).sum).to_f * @restaurant_coupon.discount) / 100)
              @pos_payment = @pos_check.pos_payments.new(payment_method_id: 4,
                                                        amount: discount_amount,
                                                        discounted_amount: discount_amount.to_f,
                                                        coupon_code: coupon_code,
                                                        paid_amount: discount_amount)
              @pos_payment.save
            end
          else
            pos_menu_list = @pos_check.pos_transactions.where(itemable_type: "MenuItem")
            discount_amount = ((before_tax_amount(@tax, pos_menu_list.map(&:total_amount).sum).to_f * @restaurant_coupon.discount) / 100)
            @restaurant_coupon.update quantity: (@restaurant_coupon.quantity-1) 
            @pos_payment = @pos_check.pos_payments.new(payment_method_id: 4,
                                                        amount: discount_amount,
                                                        discounted_amount: discount_amount.to_f,
                                                        coupon_code: coupon_code,
                                                        paid_amount: discount_amount)
            @pos_payment.save
          end
        else
          render js: "toastr.error('You reached maximum number of usage');"
        end
      elsif @applied_coupon.present?
        @pos_payments = PosPayment.where(coupon_code: @restaurant_coupon.coupon_code)
        if @pos_payments.count < @applied_coupon.total_quantity
          if @applied_coupon.menu_item_ids.present?
            pos_menu_list = @pos_check.pos_transactions.where(itemable_type: "MenuItem")
            discounted_menu_item = pos_menu_list.map { |menu| menu if @applied_coupon.menu_items.pluck(:id).include?(menu.itemable_id) }.flatten.uniq.compact
            if discounted_menu_item.present?
              discount_amount = ((before_tax_amount(@tax, discounted_menu_item.map(&:total_amount).sum).to_f * @applied_coupon.discount) / 100)
              @restaurant_coupon.update quantity: (@restaurant_coupon.quantity-1) 
              @pos_payment = @pos_check.pos_payments.new(payment_method_id: 4,
                                                        amount: discount_amount,
                                                        coupon_code: coupon_code,
                                                        discounted_amount: discount_amount.to_f,
                                                        paid_amount: discount_amount)
              @pos_payment.save
            end
          else
            pos_menu_list = @pos_check.pos_transactions.where(itemable_type: "MenuItem")
            discount_amount = ((before_tax_amount(@tax, pos_menu_list.map(&:total_amount).sum).to_f * @applied_coupon.discount) / 100)
            @restaurant_coupon.update quantity: (@restaurant_coupon.quantity-1) 
            @pos_payment = @pos_check.pos_payments.new(payment_method_id: 4,
                                                        amount: discount_amount,
                                                        coupon_code: coupon_code,
                                                        discounted_amount: discount_amount.to_f,
                                                        paid_amount: discount_amount)
            @pos_payment.save
          end
        else
          render js: "toastr.error('You reached maximum number of usage');"
        end
      end
    else
      @isAlreadyApplied = true
    end
  end

  def app_orders_list
    @branch = Branch.find_by id: params[:branch_id]
    @newOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and is_accepted = (?) and is_rejected = (?) and orders.is_cancelled = ?", @branch.restaurant_id, Date.today, false, false, false).lock(false).order("id DESC") if @branch.present?
  end

  def save_other_order_driver
    user = find_user(params[:user_id])
    if user&.status
      order = add_order_transport(@user, params[:order_id], params[:user_id], params[:amount])
      if order[:status]
        User.find(params[:user_id]).update(busy: true) if order[:order].third_party_delivery
        orderPushNotificationWorker(@user, order[:user], "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{params[:order_id]}", params[:order_id])
        firebase = firebase_connection
        group = create_track_group(firebase, params[:user_id], "26.2285".to_f, "50.5860".to_f)
        stageUpdate = web_update_order_stage(order[:order])
        order_kitchen_pusher(order[:order])
      end
    end
  end

  def update_order_status
    @order = Order.find_by id: params[:order_id]
    if(params[:order_action] == 'accept-order')
      @order.update(is_accepted: true) if @order.present?
      restaurant = @order.branch.restaurant
      busy_transporter_ids = Order.where(branch_id: @order.branch_id, is_accepted: true, is_delivered: false, is_cancelled: false).where("date(orders.created_at) = ?", Date.today).pluck(:transporter_id).uniq
      @drivers = web_branch_transport(@order.branch.id, restaurant, busy_transporter_ids)
    elsif params[:cancel_reason].present?
      @order.update(is_rejected: true, cancel_reason: params[:cancel_reason])
    end
  end

  def pos_payment
    @pos_check = PosCheck.find_by id: params[:pos_check_id]
    if @pos_check.present?
      @pos_check.update(check_status: 'saved', saved_at: Time.now, user_id: @user.id)
      @pos_check.reload
      if @pos_check.present? && @pos_check.pos_payments.where(pending_delete: true).present?
        @pos_check.pos_payments.destroy_all
      end
      pos_check_params = @pos_check.as_json
      pos_unsaved_check = @pos_check.pos_unsaved_checks
      PosCheck.removed_params.each {|k| pos_check_params.delete(k)}
      if pos_unsaved_check.present?
        @pos_check.pos_unsaved_checks.update(pos_check_params)
      else
        @pos_check.pos_unsaved_checks.create(pos_check_params)
      end
      if @pos_check.pos_transactions.present?
        @pos_check.pos_transactions.where(parent_pos_transaction_id: nil).each do |transaction|
          pos_transaction_params = transaction.as_json
          ['id', 'created_at', 'updated_at', 'parent_pos_transaction_id', 'shared_transaction_id'].each {|k| pos_transaction_params.delete(k)}
          pos_unsaved_transaction = @pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: transaction.id)
          if pos_unsaved_transaction.present?
            if pos_unsaved_transaction.is_deleted
              transaction.destroy
            else
              pos_unsaved_transaction.assign_attributes(pos_transaction_params)
            end
          else
            pos_unsaved_transaction = transaction.pos_unsaved_transactions.new(pos_transaction_params)
          end
          if pos_unsaved_transaction.save && transaction.reload.addon_pos_transactions.present?
            transaction.addon_pos_transactions.each do |addon|
              addon_params = addon.as_json
              ['id', 'created_at', 'updated_at', 'parent_pos_transaction_id', 'shared_transaction_id'].each {|k| addon_params.delete(k)}
              pos_unsaved_addon = @pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: addon.id)
              if pos_unsaved_addon.present?
                if pos_unsaved_addon.is_deleted
                  addon.destroy
                else
                  pos_unsaved_addon.assign_attributes(addon_params)
                end
              else
                pos_unsaved_addon = addon.pos_unsaved_transactions.new(addon_params)
                pos_unsaved_addon.parent_pos_unsaved_transaction_id = pos_unsaved_transaction.id
              end
              pos_unsaved_addon.save
            end
          end
        end
      end
      unless @pos_check.present? && @pos_check.pos_transactions.update_all(transaction_status: 'saved') && @pos_check.update(check_status: 'saved')
        @error = "Unable to save pos transaction"
      end
      if @pos_check.present? && params[:with_driver_save].present? && params[:driver_id].present?
        @pos_check.update(driver_id: params[:driver_id])
      end
      if @pos_check.present?
        @branch_coverage_area = BranchCoverageArea.find_by branch_id: @pos_check.branch_id, coverage_area_id: @pos_check&.address&.coverage_area_id
        if @branch_coverage_area.present? && @branch_coverage_area.third_party_delivery == false
          @drivers = User.joins(branch_transports: :branch).where(branches: { restaurant_id: @pos_check.branch.restaurant_id }).available_drivers
        end
      end
      @total_transaction = @pos_check.pos_transactions.pluck(:total_amount).sum
      @done_payment = @pos_check.pos_payments.pluck(:amount).sum
      if @done_payment < @total_transaction
        paymentAmount = params[:payment_amount].to_f > (@total_transaction - @done_payment) ? (@total_transaction - @done_payment) : params[:payment_amount].to_f
        @pos_payment = @pos_check.pos_payments.new(payment_method_id: params[:payment_method_id],
                                                    reference_number: params[:reference_promt],
                                                    amount: paymentAmount,
                                                    discounted_amount: params[:discounted_amount].to_f,
                                                    paid_amount: paymentAmount)
        if @pos_payment.save
          @pos_payment.update(currency_type_id: params[:currency_type_id]) if params[:currency_type_id].present?
          @pos_payment.attachments.attach(params[:attachments]) if params[:attachments].present?
          total_paid_amount = @pos_check.pos_payments.pluck(:paid_amount).sum
          actual_paid_amount = @pos_check.pos_transactions.pluck(:total_amount).sum
          if params[:is_gift_card] == 'true'
            render :js => "window.location.reload()";
          end    
          if actual_paid_amount == total_paid_amount
            @pos_check.update(check_status: 2)
            unless params[:is_gift_card] == 'true'
              render :js => "window.location = '#{business_partner_pos_dashboard_terminal_path(encode_token(@pos_check.branch.restaurant_id))}'"
            end
          end
        else
          @error = @pos_payment.full_messages.join(", ")
        end
      end
    end
    pos_amount_calculation(@pos_check)
  end

  def open_check_number
    @current_check = PosCheck.find_by id: params[:current_check_id]
    @branch = Branch.find_by(id: params[:selected_branch_id])
    @pos_check = @branch.present? ?
      @branch.pos_checks.find_by(check_id: params[:selected_check_no]) :
      PosCheck.find_by(check_id: params[:selected_check_no])
    if @pos_check.present?
        if ['closed', 'reopened', 'reopened_pending'].include?(@pos_check.check_status)
          if !ActiveModel::Type::Boolean.new.cast(params[:is_edit_closed_check])
            @pos_check.update(check_status: 'reopened')
          else
            @pos_check.update(check_status: 'closed')
          end
        else
          render js: "toastr.error('Check is already opened');"
        end
    else
      render js: "toastr.error('Check not found');"
    end
  end

  def delete_payment
    @pos_payment = PosPayment.find_by(id: params[:payment_id])
    unless @pos_payment.present? && @pos_payment.update(pending_delete: true)
      @error = "Payment not found"
    end
    pos_amount_calculation(@pos_payment.pos_check)
  end

  def remain_payment_popup
    @pos_check = PosCheck.find_by id: params[:pos_check_id]
    if @pos_check.present?
      # @pos_check.update(check_status: ['reopened', 'closed', 'reopened_pending'].include?(pos_check.check_status) ? 'reopened_pending' : 'pending')
      pos_transactions = PosTransaction.where(pos_check_id: params[:pos_check_id], itemable_type: 'MenuItem')
      @canContinue = [true]
      if pos_transactions.present?
        pos_transactions.each do |pos_transaction|
          pos_transaction.itemable.item_addon_categories.each do |addon_category|
            if addon_category.min_selected_quantity.to_i > 0
              if params[:pos_check_id].present?
                pos_data = PosTransaction.where(pos_check_id: params[:pos_check_id], parent_pos_transaction_id: pos_transaction.id)
              end
              total_count = pos_data.select { |pos| pos.itemable.item_addon_category_id == addon_category.id  }.count
              isValid = total_count >= addon_category.min_selected_quantity.to_i &&  pos_transaction.qty <=  pos_data.select { |pos| pos.itemable.item_addon_category_id == addon_category.id  }.map(&:qty).sum
              @canContinue.push(isValid)
              @itemName = pos_transaction.item_name unless isValid
            end
          end
        end
      end
    end
    @error_meesage = "Please add item addon #{@itemName ? 'for ' + @itemName : ''}" if @canContinue.include?(false)
    pos_amount_calculation(@pos_check)
  end

  def search_check
    @pos_checks = PosCheck.where(id: params[:pos_check_ids]&.split(' '))
    if @pos_checks.present?
      if params[:check_id].present?
        @pos_checks = @pos_checks.where(check_id: params[:check_id])
      end
      if params[:order_type_id].present?
        @pos_checks = @pos_checks.where(order_type_id: params[:order_type_id])
      end
      if params[:driver_id].present?
        @pos_checks = @pos_checks.where(driver_id: params[:driver_id])
      end
      if params[:order_status_id].present?
        @pos_checks = @pos_checks.where(id: JSON.parse(params[:order_status_id]))
      end
      if params[:order_amount].present?
        @pos_checks = @pos_checks.where(id: JSON.parse(params[:order_amount]))
      end
      if params[:table_no].present?
        @pos_checks = @pos_checks.where(id: JSON.parse(params[:table_no]))
      end
    else
      render js: 'toastr.error("invalid options")'
    end
  end

  def pos_new_check_begin_check_by_name
    branch = Branch.find_by(id: params[:selected_branch_id])
    if branch.present?
      pos_check = branch.pos_checks.create(no_of_guest: '', order_type_id: params[:selected_order_type], address_id: params[:selected_address_id], user_id: params[:selected_user_id])
      render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(branch.restaurant_id), :table => 'no_table', check: encode_token(pos_check.id))}'"
    end
  end

  def pos_seach_customer
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @admin = get_admin_user         
    @users = if @restaurant.present?
               search_user_list("customer", params[:keyword], @restaurant, params[:searched_country_id], params[:searched_state_id], params[:searched_company_id], params[:searched_restaurant_id], params[:start_date], params[:end_date])
             else
               []
             end
    branch = @restaurant.branches.first
    pos_checks = @restaurant.branches.first.pos_checks.where.not(user_id: nil)
    check_users = pos_checks.map { |a| a.user }
    user_data = check_users.push(@users).flatten.uniq.select { |user| user.contact == params[:mobile_no]}
    @customers = user_data.paginate(page: params[:page], per_page: params[:per_page])
  end

  def pos_share_item_popup
    @pos_transaction = PosTransaction.find_by id: params[:transaction_id]
    @selected_check_id = PosCheck.find_by id: params[:selected_check_id]
    @pos_checks = PosCheck.where id: params[:check_ids]
  end

  def kds_color_setting
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    if restaurant.present? && !restaurant.kds_colors.present?
      restaurant.kds_colors.create(color: 'green', minutes: 10)
      restaurant.kds_colors.create(color: 'yellow', minutes: 10)
      restaurant.kds_colors.create(color: 'red', minutes: 10)
    end
    @kds_colors = restaurant.kds_colors
    render layout: "partner_application"
  end

  def save_kds_color
    @kds_setting = KdsColor.find_by(id: params[:color_id])
    @kds_setting.update(minutes: params[:color_minute].to_i) if @kds_setting.present?
  end

  def pos_dashboard
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    # @branch = Branch.find_by_id(session[:branch_id])
    unless params[:branch_id].blank?
      @branch = restaurant.branches.where(id: params[:branch_id])&.first
      @pos_table = @branch.pos_tables.where(floor_name: params[:floor_name])&.first
      @branches_list = restaurant.branches.where(country: @pos_table.country_name)
    end
    if @user.auth_role == "business"
      @branches = restaurant.branches.order(:address)
      @restaurants = @user.restaurants.map { |r| [r.title, encode_token(r.id)] }.sort
    else
      @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:address)
    end
    @newOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and is_rejected = (?) and orders.is_cancelled = ? && orders.is_accepted = ?", restaurant, Date.today, false, false, false).lock(false).order("id DESC").select { |a| !a.pos_check_id.present? }.count
    @areas = CoverageArea.joins(:branches).where(branches: { id: @branches.pluck(:id) }).distinct.pluck(:area, :id).sort
    render layout: "partner_application"
  end

  def change_kds_type
    kds_types = ['Station', 'Expo', 'Runner', 'Customer', 'Manager']
    @pos_check = PosCheck.find_by id: params[:checkId]
    index = kds_types.index(@pos_check.kds_type) if @pos_check.present?
    @pos_check.update kds_type: kds_types[index + 1] if @pos_check.present?
  end

  def pos_no_of_table
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = Branch.find_by_id(session[:branch_id])
  end

  def kds_menu
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = restaurant.branches.first
    render layout: "partner_application"
  end

  def store_pos_table
    pos_table = PosTable.find_by(id: decode_token(params[:selected_table_id]))
    order_type_id = OrderType.find_by(name: "Dine In").id
    pos_check = pos_table.pos_checks.create(no_of_guest: params[:no_of_guest], order_type_id: order_type_id, branch_id: session[:branch_id])
    pos_table.update(no_of_guest: params[:no_of_guest], table_status: 'running') if pos_table.present?
    redirect_to business_partner_pos_new_transaction_path(restaurant_id: params[:selected_resturant_id], :table => params[:selected_table_id], check: encode_token(pos_check.id))
  end

  def cover_pos_table
    @pos_check = PosCheck.find_by(id: params[:cover_selected_check_id])
    if @pos_check.present?
      @pos_check.update(no_of_guest: params[:cover_no_of_guest])
      @pos_check.update current_seat_no: params[:cover_no_of_guest].to_i if @pos_check.current_seat_no > params[:cover_no_of_guest].to_i
      @pos_check.pos_transactions.update_all(transaction_status: 0)
      @pos_transactions = @pos_check.pos_transactions.where("seat_no > ?", params[:cover_no_of_guest].to_i)
      @pos_transactions.update_all(seat_no: 1) if @pos_transactions.present?
      if  params[:is_redirect_page] == 'true'
        render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(@pos_check.branch.restaurant_id), :table => encode_token(@pos_check.pos_table_id), check: encode_token(@pos_check.id))}'"
      end
    end
  end

  def pos_begin_table
    branch = Branch.find_by id: params[:selected_branch_id]
    @pos_table = branch.pos_tables.find_by(pos_table_no: params[:selected_table_no]) if branch.present? 
  end

  def pos_transfer_table
    branch = Branch.find_by id: params[:selected_branch_id]
    @table_will_merge = branch.pos_tables.find_by(pos_table_no: params[:entered_table_no])
    if branch.present? && @table_will_merge.present?
      @current_pos_check = PosCheck.find_by id: params[:current_pos_check_id]
    end
  end

  def pos_dashboard_dine_list
    @pos_table = PosTable.find_by id: decode_token(params["table_id"])
    @pos_checks = @pos_table.pos_checks.where(order_type_id: 1,check_status: 1) if @pos_table.present?
  end

  def pos_transfer_table_list
    @merge_check = PosCheck.find_by id: params[:pick_check_id]
    @current_check = PosCheck.find_by id: params[:current_pos_check]
    if @current_check.present? && @merge_check.present?
      if params["is_new_check"] == 'true'
        new_check = @merge_check.dup
        new_check.check_id = PosCheck.last.check_id.to_i + 1
        new_check.pos_table_id = @current_check.pos_table_id
        new_check.branch_id = params[:branch_id]
        new_check.save
        @merge_check.pos_transactions.update_all(pos_check_id: new_check.id, transaction_status: 0)
        render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(new_check&.branch&.restaurant_id), :table => encode_token(new_check&.pos_table&.id), check: encode_token(new_check&.id))}'"
      else
        @merge_check.update(is_new_merged: true,parent_check_id: @current_check.id)
      end
      @merge_check.update(check_status: 0)
      @merge_check.pos_transactions.update_all(pos_check_id: @current_check.id, transaction_status: 0)
      @total_amount = @current_check.pos_transactions.pluck(:total_amount).sum
    end
  end

  def pos_split_check
    @check = PosCheck.find_by id: params[:check_id]
    merge_checks = @check.merged_checks.where(check_status: 1)
    if @check.present? && @check.pos_transactions.present? && !merge_checks.present?
      new_check = @check.dup
      new_check.check_status = 1
      new_check.check_id = @check.branch.pos_checks.last.check_id.to_i + 1
      new_check.parent_check_id = @check.id
      new_check.save
    end
  end

  def split_checks
    @destroy_data = []
    # share_ids = params[:share_items].values.map{|a| JSON.parse(a)}.flatten
    params[:transactions].each do |check_id, transaction_ids|
      pos_check = PosCheck.find_by(id: check_id.to_i)
      if transaction_ids.empty? || transaction_ids.nil?
        @destroy_data.push(pos_check)
      else
        pos_check.update(parent_check_id: nil, is_new_merged: false, check_status: 'saved')
        PosTransaction.where(id: transaction_ids.map(&:to_i)).update_all(pos_check_id: check_id.to_i, transaction_status: 'saved')
        @pos_check = pos_check unless @pos_check.present? 
      end
    end
    # params[:share_items].each do |transaction_id, check_ids|
    #   pos_transaction = PosTransaction.find_by(id: transaction_id)
    #   check_ids = JSON.parse(check_ids)
    #   amount = pos_transaction.total_amount.to_f / check_ids.length
    #   addon_items = pos_transaction.addon_pos_transactions
    #   PosCheck.where(id: check_ids).each do |pos_check|
    #     transaction = pos_check.pos_transactions.find_by(id: pos_transaction.id)
    #     if transaction.present?
    #       transaction.update(total_amount: amount)
    #       if addon_items.present?
    #         addon_items.each do |addon|
    #           addon.update(total_amount: addon.total_amount.to_f / check_ids.length)
    #         end
    #       end
    #     else
    #       transaction = pos_transaction.dup
    #       transaction.pos_check_id = pos_check.id
    #       transaction.total_amount = amount
    #       transaction.save
    #       if addon_items.present?
    #         addon_items.each do |addon|
    #           dup_addon = addon.dup
    #           dup_addon.pos_check_id = pos_check&.id
    #           dup_addon.parent_pos_transaction_id = transaction.id
    #           dup_addon.total_amount = addon.total_amount.to_f / check_ids.length
    #           dup_addon.save
    #         end
    #       end
    #     end
    #   end
    # end
    # @destroy_data.map { |data| data.destroy }
    render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(@pos_check&.branch&.restaurant_id), :table => encode_token(@pos_check&.pos_table_id), check: encode_token(@pos_check&.id))}'"
  end

  def get_addresses
    user = User.find_by_id(params[:user_id])
    if user.present?
      @addresses = user.addresses
    end
  end

  def minimum_coverage
    restaurant = Restaurant.find_by_id(decode_token(params[:restaurant_id]))
    address = Address.find_by_id(params[:address_id])
    amount = 0
    if restaurant.present? && address.present?
      amount = BranchCoverageArea.find_by(branch_id: restaurant&.branch&.id, coverage_area_id: address.coverage_area.id )&.minimum_amount
    end
    if params[:modal_id] == 'beginCheckByNamePopupCheckId'
      check = PosCheck.find_by id: params[:check_id]
      check.update(address_id: address.id, user_id: params[:customer_id])
    end
    render json: {minimum_coverage_amount: (amount || 0.0), modal_id: params[:modal_id], user_name: check&.user&.name, address: check&.address&.area_name, user_id: params[:customer_id] }
  end

  def create_customer_check
    branch = Restaurant.find_by(id: decode_token(params[:restaurant_id]))&.branch
    pos_check = PosCheck.new(
      order_type_id: params[:check_type].present? ? params[:check_type] : 2,
      branch_id: branch.id,
      address_id: Address.find_by_id(params[:address_id])&.id,
      user_id: User.find_by_id(params[:customer_id])&.id
    )
    if pos_check.save
      render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: params[:restaurant_id], check: encode_token(pos_check.id))}'"
    end
  end

  def cancel_check
    pos_check = PosCheck.find_by(id: params[:parent_check_id])
    child_checks = pos_check.merged_checks.where(id: params[:other_check_id])
    child_pos_transactions = PosTransaction.where(pos_check_id: child_checks.pluck(:id))
    if child_checks.present? && PosTransaction.where(pos_check_id: child_checks.pluck(:id)).empty?
      child_checks.destroy_all
    elsif child_pos_transactions.present?
      child_checks.each do |child_check|
        transaction_ids = []
        pos_transactions = PosTransaction.where(
          'pos_check_id = ? and shared_transaction_id != ?',
          child_check.id, 0)
        if pos_transactions.present?
          pos_transactions.each do |pos_transaction|
            transaction_ids.push(pos_transaction&.id)
            main_transaction = pos_transaction.parent_shared_transaction
            main_transaction.update(total_amount: main_transaction.total_amount + pos_transaction.total_amount)
            # if pos_transaction.addon_pos_transactions.present?
            #   pos_transaction.addon_pos_transactions.each do |addon|
            #     main_addon_transaction = addon.parent_shared_transaction
            #     main_addon_transaction.update(total_amount: main_addon_transaction.total_amount + addon.total_amount)
            #     transaction_ids.push(addon&.id)
            #   end
            # end
          end
        end
        PosTransaction.where(id: transaction_ids).destroy_all
        unless child_check.reload.pos_transactions.length > 0
          child_check.destroy
        end
      end
    end
  end

  def share_check
    @pos_transaction = PosTransaction.find_by(id: params[:transaction_id])
    check_length = params[:check_ids].length + 1
    addons = @pos_transaction.addon_pos_transactions
    addon_amount = {}
    addons.each do |addon|
      amount = (addon.total_amount / check_length)
      addon_amount[addon.id] = amount
      addon.update(total_amount: amount, transaction_status: 'shared_pending')
    end
    if @pos_transaction.present?
      pos_checks = PosCheck.where(id: params[:check_ids])
      pos_checks.each do |check|
        transaction = @pos_transaction.dup
        transaction.pos_check_id = check.id
        transaction.total_amount = @pos_transaction.total_amount.to_f / check_length
        transaction.shared_transaction_id = @pos_transaction.id
        transaction.transaction_status = 'shared_pending'
        if transaction.save && addons.length > 0
          addons.each do |addon|
            addon_transaction = addon.dup
            addon_transaction.total_amount = addon_amount[addon.id]
            addon_transaction.pos_check_id = check.id
            addon_transaction.parent_pos_transaction_id = transaction.id
            addon_transaction.transaction_status = 'shared_pending'
            addon_transaction.shared_transaction_id = addon.id
            addon_transaction.save
          end
        end
      end
      @pos_transaction.update(total_amount: @pos_transaction.total_amount / check_length, transaction_status: 'shared_pending')
    end
  end

  def add_check
    @check = PosCheck.find_by id: params[:parent_check_id]
    if @check.present? && @check.merged_checks.where(check_status: 1).count < 9
      @new_check = @check.dup
      @new_check.check_status = 1
      @new_check.check_id = @check.branch.pos_checks.last.check_id.to_i + 1
      @new_check.parent_check_id = @check.id
      @new_check.save
    end
  end

  def pos_status_change
    @pos_check = PosCheck.find_by id: params[:pos_check_id]
    @isUpdate = false
    if @pos_check.present? 
      @pos_check.pos_transactions.update_all(transaction_status: 0)
      if params[:selected_status] == "1" && @pos_check.order_type_id != 1
        @pos_check.pos_transactions.update_all(seat_no: 1)
      elsif params[:selected_status].to_i > 1
        @pos_check.pos_transactions.update_all(seat_no: 0)
      end
      @pos_check.update(order_type_id: params[:selected_status].to_i)
      if @pos_check.pos_table.present?
        if @pos_check.pos_table.pos_checks.pluck(:order_type_id).include?(1)
          @pos_check.pos_table.update(table_status: 1)
        else
          @pos_check.pos_table.update(table_status: 0)
        end
      end
    end
  end

  def pos_bind_dinein_table
    @pos_check = PosCheck.find_by id: params[:selected_check_id]
    @branch = Branch.find_by id: params[:selected_branch_id]
    @pos_table = @branch.pos_tables.find_by(pos_table_no: params[:selected_table_no]) if @branch.present?
    @pos_check.update(pos_table_id: @pos_table.id, check_status: 0) if @pos_table.present?
    if @pos_check.present? && @pos_check.pos_table.present?
      @pos_check.pos_transactions.update_all(transaction_status: 0)
      @pos_check.update(order_type_id: params[:selected_status] || 1)
      if @pos_check.pos_table.present?
        if @pos_check.pos_table.pos_checks.pluck(:order_type_id).include?(1)
          @pos_check.pos_table.update(table_status: 1)
        else
          @pos_check.pos_table.update(table_status: 0)
        end
      end
    end
  end

  def pos_pickup_check
    branch = Branch.find_by id: params[:branch_id]
    @pos_checks = branch.pos_checks.where(is_new_merged: false, check_status: 'saved')
  end

  def pos_pickup_check_list
    check = PosCheck.find_by id: params[:check_id]
    render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(check&.branch&.restaurant_id), :table => (check&.pos_table&.id ? encode_token(check&.pos_table&.id) : 'no_table'), check: encode_token(check&.id))}'"
  end

  def print_check
    @pos_table = PosTable.find_by(id: params[:table_id])
    if @pos_table.present? && params[:pos_check_id].present?
      @pos_check = @pos_table.pos_checks.find_by(id: params[:pos_check_id])
    else
      @pos_check = PosCheck.find_by(id: params[:pos_check_id])
    end
    unless @pos_check.present?
     render js: "toastr.error('Check not found')"
    end
  end

  def pos_cancel_transaction
    @pos_table = PosTable.find_by(id: params[:table_id])
    if params[:check_id].present? 
      @pos_check = PosCheck.find_by(id: params[:check_id])
      @pos_check.pos_payments.present? && @pos_check.pos_payments.where(pending_delete: true).update_all(pending_delete: false)
      if @pos_check.pos_unsaved_checks.present?
        @pos_check.pos_unsaved_transactions.update_all(is_deleted: false)
        pos_check_params = @pos_check.pos_unsaved_checks.last.as_json
        ['id', 'created_at', 'updated_at', 'parent_unsaved_check_id', 'pos_check_id', 'address_id', 'user_id', 'driver_id', 'saved_at'].each {|k| pos_check_params.delete(k)}
        @pos_check.assign_attributes(pos_check_params)
        @pos_check.check_status = ['reopened_pending', 'reopened', 'closed'].include?(@pos_check&.reload&.check_status) ? 'closed' : 'saved'
        if @pos_check.save && @pos_check.pos_transactions.present?
          @pos_check.pos_transactions.where(parent_pos_transaction_id: nil).each do |transaction|
            pos_unsaved_transaction = @pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: transaction.id)
            if pos_unsaved_transaction.present?
              pos_transaction_params = pos_unsaved_transaction.as_json
              ['id', 'created_at', 'updated_at', 'parent_pos_unsaved_transaction_id', 'pos_transaction_id', 'is_deleted'].each {|k| pos_transaction_params.delete(k)}
              transaction.assign_attributes(pos_transaction_params)
              transaction.transaction_status = 'saved'
              if transaction.save && transaction.addon_pos_transactions.present?
                transaction.addon_pos_transactions.each do |addon|
                  pos_unsaved_addon = @pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: addon.id)
                  if pos_unsaved_addon.present?
                    addon_params = pos_unsaved_addon.as_json
                    ['id', 'created_at', 'updated_at', 'parent_pos_unsaved_transaction_id', 'pos_transaction_id', 'is_deleted'].each {|k| addon_params.delete(k)}
                    addon.assign_attributes(addon_params)
                    addon.transaction_status = 'saved'
                    addon.save
                  elsif addon.transaction_status.eql?('pending')
                    addon.destroy
                  end
                end
              end
            elsif transaction.transaction_status.eql?('pending')
              transaction.destroy
            end
          end
        end
      elsif @pos_check.check_status.eql?('pending')
        @pos_check.destroy
        @pos_table.update(table_status: 0) if @pos_table.present? && @pos_table.table_status == 'running' && @pos_table.pos_checks.pluck(:order_type_id).count(1) <= 1
        # @pos_check.pos_transactions.destroy_all
      end
    # else
    #   @pos_table.pos_transactions.destroy_all if @pos_table.present?
    #   @pos_table.update(table_status: 0) if @pos_table.present?
    end
    redirect_to business_partner_pos_dashboard_terminal_path(encode_token(@pos_check.branch.restaurant_id))
  end

  def remove_last_check
    pos_check = PosCheck.find_by(id: params[:check_id])
    shared_transactions = params[:transaction_ids].present? ? pos_check.pos_transactions.where(
      '(id IN (?) or parent_pos_transaction_id IN (?)) and shared_transaction_id IS NOT NULL ',
      params[:transaction_ids], params[:transaction_ids]
    )  : []
    transaction_ids = []
    if pos_check.present? && shared_transactions.present?
      shared_transactions.each do |transaction|
        main_transaction = transaction.parent_shared_transaction
        main_transaction.update(total_amount: main_transaction&.total_amount + transaction&.total_amount.to_f)
        transaction_ids.push(main_transaction.id)
        transaction.destroy
      end
      pos_check.destroy
      @transactions = PosTransaction.where(id: transaction_ids)
    elsif pos_check.present?
      pos_check.destroy
    else
      @error = 'Check not found'
    end
  end

  def pickup_tables
    pos_table = PosTable.find_by(pos_table_no: params[:table_no])
    if pos_table.present?
      @pos_check = pos_table.pos_checks.where(order_type_id: 1, is_new_merged: false, check_status: 'saved')
      if @pos_check.present?
        # @pos_check = pos_table.pos_checks.where("check_type != ?",0)
        if @pos_check.length == 1
          render :js => "window.location = '#{business_partner_pos_new_transaction_path(restaurant_id: encode_token(@pos_check.last&.pos_table&.branch&.restaurant_id), :table => encode_token(@pos_check.last&.pos_table&.id), check: encode_token(@pos_check.last&.id))}'"
        end
      else
        @error = 'Check not found'
      end
    else
      @error = "Table not found"
    end
  end

  def begin_check
    # restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    pos_table = PosTable.find_by(id: decode_token(params[:table_id]))
    if pos_table.present?
      pos_check = pos_table.pos_checks.new(
        no_of_guest: params[:no_of_guest],
        order_type_id: params[:check_type].present? ? params[:check_type] : (params[:is_dashboard].present? ? 1 : 2),
        branch_id: pos_table.branch_id
      )
      if pos_check.save
        redirect_to business_partner_pos_new_transaction_path(restaurant_id: params[:restaurant_id], :table => encode_token(pos_table.id), check: encode_token(pos_check.id))
      else
        redirect_to :back
      end 
    else
      pos_check = PosCheck.new(
        no_of_guest: params[:no_of_guest],
        order_type_id: params[:check_type].present? ? params[:check_type] : (params[:is_dashboard].present? ? 1 : 2),
        branch_id: params[:branch_id]
      )
      if pos_check.save
        redirect_to business_partner_pos_new_transaction_path(restaurant_id: params[:restaurant_id], check: encode_token(pos_check.id))
      else
        redirect_to :back
      end 
    end
  end

  def transfer_check_detail
    parent_check = PosCheck.find_by(id: decode_token(params[:mergable_check_id]))
    @child_check = PosCheck.find_by(check_id: params[:selected_check_no])
    if @child_check.id == parent_check.id
      @error = 'Check Not Found'
    elsif @child_check.order_type_id != parent_check.order_type_id
      @error = "Invalid Check Type. Please Select Same Check Type."
    else
      if parent_check.present? && !@child_check.parent_check_id.present?
        # child_ids = @child_check.pos_transactions.pluck(:id)
        unless @child_check.present?
          # @child_check.update(parent_check_id: parent_check.id, pos_table_id: parent_check.pos_table_id)
          # @child_check.pos_transactions.update_all(pos_check_id: parent_check.id)
          # @child_transactions = PosTransaction.where(id: child_ids, parent_pos_transaction_id: nil)
        # else
          @error = "Check Not Found"
        end
      else
        @error = 'Check Not Found'
      end
    end
  end

  def transfer_check
    parent_check = PosCheck.find_by(id: params[:parent_check_id])
    child_check = PosCheck.find_by(id: params[:child_check_id])
    child_ids = child_check.pos_transactions.pluck(:id)
    child_check.update(parent_check_id: parent_check.id, pos_table_id: parent_check.pos_table_id, is_new_merged: true, check_status: 0)
    child_check.pos_transactions.update_all(pos_check_id: parent_check.id)
    @child_transactions = PosTransaction.where(id: child_ids, parent_pos_transaction_id: nil)
  end

  def pos_no_of_chair_per_table
    @branch = Branch.find_by id: params[:branch_id]
    pos_tables = PosTable.where(floor_name: params[:original_floor_name], branch_id: params[:original_branch_id])
    if @branch.present?
      if params[:original_floor_name].present?
        pos_tables.destroy_all unless pos_tables.blank?
        params["pos_table_no"].each_with_index do |table, index|
          @branch.pos_tables.create(pos_table_no: table, no_of_chair: params["no_of_chair"][index], country_name: params[:country_name], floor_name: params[:floor_name], created_by_id: params[:created_by_id]) if params["no_of_chair"][index].present?
          flash[:success] = "Floor updated successfully!"
        end
      else
        params["pos_table_no"].each_with_index do |table, index|
          @branch.pos_tables.create(pos_table_no: table, no_of_chair: params["no_of_chair"][index], country_name: params[:country_name], floor_name: params[:floor_name], created_by_id: params[:created_by_id]) if params["no_of_chair"][index].present?
        end
        flash[:success] = "Floor created successfully!"
      end
    end
  end

  def assign_driver
    @check = PosCheck.find_by id: params[:check_id]
    @check.update driver_id: params[:driver_id] if @check.present?
    render :js => "window.location = '#{business_partner_pos_dashboard_path(encode_token(@check.branch.restaurant_id))}'"
  end

  def save_check
    @pos_check = PosCheck.find_by(id: params[:check_id])
    pos_check_params = @pos_check.as_json
    pos_unsaved_check = @pos_check.pos_unsaved_checks
    PosCheck.removed_params.each {|k| pos_check_params.delete(k)}
    if pos_unsaved_check.present?
      @pos_check.pos_unsaved_checks.update(pos_check_params)
    else
      @pos_check.pos_unsaved_checks.create(pos_check_params)
    end
    if @pos_check.pos_transactions.present?
      @pos_check.pos_transactions.where(parent_pos_transaction_id: nil).each do |transaction|
        pos_transaction_params = transaction.as_json
        ['id', 'created_at', 'updated_at', 'parent_pos_transaction_id', 'shared_transaction_id'].each {|k| pos_transaction_params.delete(k)}
        pos_unsaved_transaction = @pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: transaction.id)
        if pos_unsaved_transaction.present?
          if pos_unsaved_transaction.is_deleted
            transaction.destroy
          else
            pos_unsaved_transaction.assign_attributes(pos_transaction_params)
          end
        else
          pos_unsaved_transaction = transaction.pos_unsaved_transactions.new(pos_transaction_params)
        end
        if pos_unsaved_transaction.save && transaction.reload.addon_pos_transactions.present?
          transaction.addon_pos_transactions.each do |addon|
            addon_params = addon.as_json
            ['id', 'created_at', 'updated_at', 'parent_pos_transaction_id', 'shared_transaction_id'].each {|k| addon_params.delete(k)}
            pos_unsaved_addon = @pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: addon.id)
            if pos_unsaved_addon.present?
              if pos_unsaved_addon.is_deleted
                addon.destroy
              else
                pos_unsaved_addon.assign_attributes(addon_params)
              end
            else
              pos_unsaved_addon = addon.pos_unsaved_transactions.new(addon_params)
              pos_unsaved_addon.parent_pos_unsaved_transaction_id = pos_unsaved_transaction.id
            end
            pos_unsaved_addon.save
          end
        end
      end
    end
    unless @pos_check.present? && @pos_check.pos_transactions.update_all(transaction_status: 'saved') && @pos_check.update(check_status: 'saved')
      @error = "Unable to save pos transaction"
    end
    if @pos_check.present? && params[:with_driver_save].present? && params[:driver_id].present?
      @pos_check.update(driver_id: params[:driver_id])
    end
    if @pos_check.present?
      @branch_coverage_area = BranchCoverageArea.find_by branch_id: @pos_check.branch_id, coverage_area_id: @pos_check&.address&.coverage_area_id
      if @branch_coverage_area.present? && @branch_coverage_area.third_party_delivery == false
        @drivers = User.joins(branch_transports: :branch).where(branches: { restaurant_id: @pos_check.branch.restaurant_id }).available_drivers
      end
    end
    if @pos_check.present? && @pos_check.pos_payments.where(pending_delete: true).present?
      gift_card = @pos_check.pos_payments.find_by(payment_method_id: 4)
      coupon = InfluencerCoupon.find_by coupon_code: gift_card.coupon_code if gift_card.present?
      coupon = RestaurantCoupon.find_by coupon_code: gift_card.coupon_code if gift_card.present? && !coupon.present?
      coupon.update quantity: (coupon.quantity + 1) if coupon.present?
      @pos_check.pos_payments.where(pending_delete: true).destroy_all
    end
    if @pos_check.present? && @pos_check.pos_transactions.present?
      total_paid_amount = @pos_check.pos_payments.pluck(:paid_amount).sum
      actual_paid_amount = @pos_check.pos_transactions.pluck(:total_amount).sum
      if actual_paid_amount == total_paid_amount || @pos_check.is_full_discount
        @pos_check.update(check_status: 2, saved_at: Time.now)
      end
    end
    # if params[:with_driver_save] == 'true' && params[:driver_id].present?
      # render :js => "window.location.reload()"
    if params[:is_split_check_btn] == 'true' || (params[:is_save_check_btn].present? && (!@drivers.present? || @branch_coverage_area&.third_party_delivery != false || @pos_check.driver_id.present? || @pos_check.order_type_id != 2))
      place_manual_order(@pos_check, params[:amount], params[:payment_method_id]) if @pos_check.order_type_id.eql?(2) && !@pos_check.order.present?
      #render :js => "window.location = '#{business_partner_pos_dashboard_path(encode_token(@pos_check.branch.restaurant_id))}'"
    end
  end

  def driver_list
    @pos_check = PosCheck.find_by(id: params[:pos_check_id])
    if @pos_check.present?
      @branch_coverage_area = BranchCoverageArea.find_by branch_id: @pos_check.branch_id, coverage_area_id: @pos_check&.address&.coverage_area_id
      # if @branch_coverage_area.present? && @branch_coverage_area.third_party_delivery == false
        restaurant = @pos_check.branch.restaurant
        busy_transporter_ids = Order.where(branch_id: @pos_check.branch_id, is_accepted: true, is_delivered: false, is_cancelled: false).where("date(orders.created_at) = ?", Date.today).pluck(:transporter_id).uniq
        @drivers = web_branch_transport(@pos_check.branch.id, restaurant, busy_transporter_ids)
        # @drivers = User.joins(branch_transports: :branch).where(branches: { restaurant_id: @pos_check.branch.restaurant_id }).not_available_drivers
      # end
    end
  end

  def pos_new_transaction
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    branch = restaurant.branches.find_by_id(session[:branch_id])
    @pos_table = branch.pos_tables.find_by(id: decode_token(params[:table]))
    if params[:check].present?
      @pos_check = PosCheck.find_by(id: decode_token(params[:check]))
    else
      @pos_check = @pos_table.pos_checks.find_by(order_type_id: 1)
      # @all_transactions = @pos_table.pos_transactions.where(pos_check_id: nil)
    end
    @newOrders = Order.joins(branch: :restaurant).where("branches.restaurant_id = ? and DATE(orders.created_at) = (?) and is_rejected = (?) and orders.is_cancelled = ? && orders.is_accepted = ?", restaurant, Date.today, false, false, false).lock(false).order("id DESC").select { |a| !a.pos_check_id.present? }.count
    @pos_check.pos_unsaved_transactions.update_all(is_deleted: false)
    @pos_check.pos_payments.where(pending_delete: true).update_all(pending_delete: false)
    # check_ids = [@pos_check.id]
    # check_ids << @pos_check.merged_checks.pluck(:id)
    # check_ids = check_ids.flatten.compact
    # @all_transactions = PosTransaction.includes([:pos_check]).where(pos_check_id: check_ids)
    # @categories = MenuCategory.joins(:branch).where(branches: { restaurant_id: restaurant.id, is_approved: true}, include_in_pos: true)
    @categories = MenuCategory.where(branch_id: session[:branch_id], include_in_pos: true)
    @all_transactions = @pos_check.pos_transactions
    # transactions = {}
    # @pos_table.pos_transactions.order('created_at asc').each do |transaction|
    #   if transaction.parent_pos_transaction_id.nil?
    #     transactions[transaction.id] = [transaction]
    #   else
    #     transactions[transaction.parent_pos_transaction_id].push(transaction)
    #   end
    # end
    @transactions = @all_transactions.where(parent_pos_transaction_id: nil)
    @tax = Tax.where(country_id: restaurant.country_id).pluck(:percentage).sum
    @tax_name = Tax.where(country_id: restaurant.country_id).pluck(:name)

    # @branch = restaurant.branches.first
    @branch = branch
    if @user.auth_role == "business"
      @branches = restaurant.branches.order(:address)
      @restaurants = @user.restaurants.map { |r| [r.title, encode_token(r.id)] }.sort
    else
      @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:address)
    end
    # @areas = CoverageArea.joins(:branches).where(branches: { id: @branches.pluck(:id) }).distinct.pluck(:area, :id).sort

    @areas = CoverageArea.joins(:branches).where(branches: { id: branch.id }).distinct.pluck(:area, :id).sort

    render layout: "partner_application"
  end

  def pos_menu_items
    @menu_items = MenuItem.where(menu_category_id: params[:category_id], include_in_pos: true)
  end

  def pos_menu_categories
    @categories = MenuCategory.joins(:branch).where(branches: { restaurant_id: decode_token(params[:restaurant_id]), is_approved: true}, include_in_pos: true)
  end

  def add_menu_addon_pos_transaction
    @menu_item_addon = ItemAddon.find_by(id: params[:menu_item_id])
    @isUpdate = false
    if @menu_item_addon.present? && (params[:pos_table_id].present? || params[:pos_check_id].present?)
      if params[:pos_check_id].present?
        pos_check = PosCheck.find_by(id: params[:check_id])
        pos_check.update(check_status: ['reopened', 'closed', 'reopened_pending'].include?(pos_check.check_status) ? 'reopened_pending' : 'pending') if pos_check.present?
        @pos_table_transactions = @menu_item_addon.pos_transactions.where(pos_check_id: params[:pos_check_id], parent_pos_transaction_id: params[:parent_pos_transaction_id])
      else
        @pos_table_transactions = @menu_item_addon.pos_transactions.where(pos_table_id: params[:pos_table_id], parent_pos_transaction_id: params[:parent_pos_transaction_id])
      end
      if @pos_table_transactions.present?
        @pos_transaction = @pos_table_transactions.last
        qty = @pos_transaction.qty + params[:qty].to_i
        @pos_transaction.assign_attributes(qty: qty, total_amount: @menu_item_addon.addon_price * qty)
      else
        @pos_transaction = @menu_item_addon.item_addon_category.branch.pos_transactions.new(
            itemable: @menu_item_addon,
            qty: 1,
            item_name: @menu_item_addon.addon_title, item_price: @menu_item_addon.addon_price,
            total_amount: @menu_item_addon.addon_price * params[:qty].to_i, pos_table_id: params[:pos_table_id].to_i == 0 ? nil : params[:pos_table_id],
            parent_pos_transaction_id: params[:parent_pos_transaction_id],
            pos_check_id: params[:pos_check_id]
          )
      end
      if params[:pos_check_id].present?
        total_pos_transaction = @pos_transaction.parent_pos_transaction.addon_pos_transactions.where(pos_check_id: params[:pos_check_id])
      else
        total_pos_transaction = @pos_transaction.parent_pos_transaction.addon_pos_transactions.where(pos_table_id: params[:pos_table_id])
      end
      totalAddon = ItemAddon.where(item_addon_category_id: @menu_item_addon.item_addon_category_id).pluck(:id)
      total_qty = 0
      total_pos_transaction.each do |pos_data|
        total_qty += pos_data.qty if totalAddon.include?(pos_data.itemable_id) && pos_data.parent_pos_transaction.present? &&  pos_data.parent_pos_transaction.itemable_id == params[:selected_menu_id].to_i
      end
      total_max_qty = @menu_item_addon.item_addon_category.max_selected_quantity.to_i * @pos_transaction.parent_pos_transaction.qty.to_i
      if total_max_qty > total_qty
        if @pos_transaction.save
          @isUpdate = true
          if params[:pos_check_id].present?
            @addon_count = PosTransaction.where(parent_pos_transaction_id: params[:parent_pos_transaction_id], pos_check_id: params[:pos_check_id]).pluck(:qty).sum
          else
            @addon_count = PosTransaction.where(parent_pos_transaction_id: params[:parent_pos_transaction_id], pos_table_id: params[:pos_table_id]).pluck(:qty).sum
          end
          @success = 'Transaction added.'
        else
          @error = 'Unable to add transaction'
        end
      end
    elsif params[:transaction_id].present?
      @pos_transaction = PosTransaction.find_by(id: params[:transaction_id])
      qty = @pos_transaction.qty + params[:qty].to_i
      @pos_transaction.assign_attributes(qty: qty, total_amount: @pos_transaction.item_price * qty)
      @pos_transaction.save
      @menu_item_addon = @pos_transaction.itemable
    else
      @error = 'Menu Item not found'
    end
    @additional_amount = @menu_item_addon.addon_price * params[:qty].to_i
    pos_check = PosCheck.find_by(id: params[:pos_check_id]) unless pos_check.present?
    pos_amount_calculation(pos_check)
  end

  def pos_save_comment
    @pos_transaction = PosTransaction.find_by id: params['selected_menuaddon_transaction_id']
    @pos_transaction.update(comments: params[:comments]) if @pos_transaction.present?
  end

  def pos_save_item_comment
    if params[:pos_transaction_id].present? && (params[:comments].present? || params[:kitchen_instructions].present? || params[:duration].present?)
      @pos_transaction = PosTransaction.find_by id: params['pos_transaction_id']
      if @pos_transaction.present? && @pos_transaction.itemable_type.eql?('MenuItem')
        @pos_transaction.update(comments: params[:comments]) if params[:comments].present?
        @pos_transaction.update(kitchen_instructions: params[:kitchen_instructions]) if params[:kitchen_instructions].present?
        @pos_transaction.update(duration: params[:duration].to_i) if params[:duration].present?
      else
        @error = "Please select menu item for comment"
      end
    elsif params[:pos_transaction_id].empty?
      @error = 'Please select menu item for comment'
    elsif params[:comments].empty?
      @error = 'Please enter comment'
    elsif params[:kitchen_instructions].empty?
      @error = 'Please select Kitchen Instructions'
    end
  end

  def check_item_addon
    if params[:pos_check_id].present?
      pos_check = PosCheck.find_by(id: params[:pos_check_id])
      pos_check.update(check_status: ['reopened', 'closed', 'reopened_pending'].include?(pos_check.check_status) ? 'reopened_pending' : 'pending')
      pos_transactions = PosTransaction.where(pos_check_id: pos_check&.id || params[:pos_check_id], itemable_type: 'MenuItem')
    else
      pos_table = PosTable.find_by(id: params[:table_id])
      pos_transactions = PosTransaction.where(pos_table_id: pos_table&.id || params[:pos_table_id], itemable_type: 'MenuItem')
    end
    @canContinue = [true]
    if pos_transactions.present?
      pos_transactions.each do |pos_transaction|
        pos_transaction.itemable.item_addon_categories.each do |addon_category|
          if addon_category.min_selected_quantity.to_i > 0
            if params[:pos_check_id].present?
              pos_data = PosTransaction.where(pos_check_id: params[:pos_check_id], parent_pos_transaction_id: pos_transaction.id)
            else
              pos_data = PosTransaction.where(pos_table_id: params[:pos_table_id], parent_pos_transaction_id: pos_transaction.id)
            end
            total_count = pos_data.select { |pos| pos.itemable.item_addon_category_id == addon_category.id  }.count
            isValid = total_count >= addon_category.min_selected_quantity.to_i &&  pos_transaction.qty <=  pos_data.select { |pos| pos.itemable.item_addon_category_id == addon_category.id  }.map(&:qty).sum
            @canContinue.push(isValid)
            @itemName = pos_transaction.item_name unless isValid
          end
        end
      end
    end
    render json: {canContinue: !@canContinue.include?(false), itemName: @itemName}
  end

  def get_discount_percentage
    if params[:branch_id].present?
      @pos_check = PosCheck.find_by(id: params[:pos_check_id])
      @offers = Offer.where("branch_id = ? and start_time <= ? and end_time >= ? and include_in_pos = ?", params[:branch_id], DateTime.now, DateTime.now, true).map{|offer| offer if (!offer.limited_quantity || (offer.limited_quantity && offer.pos_checks.length <= offer.quantity))}.compact
    else
      render js: 'toastr.error("Branch not found")'
    end
  end

  def delete_discount_percentage
    @pos_check = PosCheck.find_by(id: params[:pos_check_id])
    if @pos_check.present?
      @pos_check.update(offer_id: nil, is_full_discount: false)
    else
      @error = 'Check not fond'
    end
    pos_amount_calculation(@pos_check)
  end

  def apply_discount_percentage
    branch = Branch.find_by(id: params[:branch_id])
    if branch.present?
      @pos_check = branch.pos_checks.find_by(id: params[:pos_check_id])
      unsaved_transactions = @pos_check.pos_unsaved_transactions.includes(:pos_transaction).where(
        'pos_transactions.transaction_status != ?', PosTransaction.transaction_statuses["saved"]).pluck(:pos_transaction_id)
      gift_card = @pos_check.pos_payments.where(payment_method_id: 4, pending_delete: false)
      if @pos_check.present? && gift_card&.length > 0
        @error = "Gift card already appplied"
      else
        @offer = Offer.find_by(id: params[:offer_id])
        if @pos_check.present? && @offer.present? && (@pos_check.offer_id.nil? ||
            (@pos_check.offer_id.present? && @pos_check.offer_id != @offer.id ))
          addons = ItemAddon.where(item_addon_category_id: @offer.menu_item.item_addon_categories.pluck(:id)) if @offer.menu_item_id.present?
          discount_per = @offer.discount_percentage.to_f == 0.0 && @offer.offer_title.eql?('Buy 1 Get 1 Free') ? 50 : @offer.discount_percentage
          total_amount = @pos_check.pos_transactions.where.not(id: unsaved_transactions).sum(:total_amount).to_f
          if @pos_check.user_id.present?
            restaurant = branch.restaurant
            checks = PosCheck.where(user_id: @pos_check.user_id, offer_id: @offer&.id)
            more_quantity = checks.length + 1 > (@offer.limit.present? ? @offer.limit.to_i : @offer&.admin_offer&.limit.to_i)
            # if
            #   @error = "Limit exceeds. User can use offer for limited time."
            # else
            @tax = Tax.where(country_id: restaurant.country_id).pluck(:percentage).sum
            @amount = @offer.offer_type.eql?('individual') ? unsaved_transactions.empty? ?
            @pos_check.pos_transactions.where(
                '((itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?)))', 
                    "MenuItem", @offer&.menu_item_id, "ItemAddon", addons.pluck(:id)).sum(:total_amount).to_f :
              @pos_check.pos_transactions.where(
                '((itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?))) && id NOT IN (?)',
                  "MenuItem", @offer&.menu_item_id, "ItemAddon", addons.pluck(:id), unsaved_transactions).sum(:total_amount).to_f :
              @pos_check.pos_transactions.sum(:total_amount).to_f
            tax_amount = taxonlyamount(@tax, @amount)
            if @offer.discount_percentage.to_f == 100 && !more_quantity
              @discount_percent = (@amount * discount_per.to_f) / 100
              if ActiveModel::Type::Boolean.new.cast(params[:is_quick_pay])
                @pos_check.update(offer_id: params[:offer_id], is_full_discount: true, check_status: 'closed')
              else
                @pos_check.update(offer_id: params[:offer_id], is_full_discount: true)
              end
            else
              @discount_percent = ((@amount - tax_amount) * discount_per.to_f) / 100
              @pos_check.update(offer_id: params[:offer_id], is_full_discount: false)
            end
            @amount = total_amount  - @discount_percent.to_f
            # end
          # elsif @offer.limited_quantity && @offer.quantity > @pos_check.pos_transactions.length
          #   @error = "Offer can apply on more then #{@offer.quantity} quantity"
          elsif @offer.menu_item_id.present? && @pos_check.pos_transactions.find_by(itemable_type: 'MenuItem', itemable_id: @offer.menu_item_id).nil?
            @error = "Offer will Apply on #{@offer.menu_item&.item_name}"
          else
            @tax = Tax.where(country_id: branch&.restaurant&.country_id).pluck(:percentage).sum
            @amount = @offer.offer_type.eql?('individual') ? unsaved_transactions.empty? ?
              @pos_check.pos_transactions.where(
                '((itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?)))', 
                    "MenuItem", @offer&.menu_item_id, "ItemAddon", addons.pluck(:id)).sum(:total_amount).to_f :
              @pos_check.pos_transactions.where(
                '((itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?))) && id NOT IN (?)', 
                    "MenuItem", @offer&.menu_item_id, "ItemAddon", addons.pluck(:id), unsaved_transactions).sum(:total_amount).to_f :
              @pos_check.pos_transactions.sum(:total_amount).to_f
            tax_amount = taxonlyamount(@tax, @amount)
            @discount_percent = ((@amount - tax_amount) * discount_per.to_f) / 100
            @amount = total_amount - @discount_percent.to_f
            @pos_check.update(offer_id: params[:offer_id], is_full_discount: false)
          end
        end
      end
    end
  end

  def add_pos_transaction
    @menu_item = MenuItem.find_by(id: params[:menu_item_id])
    if params[:pos_check_id].present?
      pos_check = PosCheck.find_by(id: params[:pos_check_id])
      pos_check.update(check_status: ['reopened', 'closed', 'reopened_pending'].include?(pos_check.check_status) ? 'reopened_pending' : 'pending')
      pos_transactions = PosTransaction.where(pos_check_id: pos_check&.id || params[:pos_check_id], itemable_type: 'MenuItem')
    else
      pos_table = PosTable.find_by(id: params[:pos_table_id])
      pos_transactions = PosTransaction.where(pos_table_id: pos_table&.id || params[:pos_table_id], itemable_type: 'MenuItem')
    end
    @canCountinue = [true]
    # without_addon_transaction = pos_transactions.select { |pos| !pos.addon_pos_transactions.present? && !pos.comments.present? }
    # @deleted_item = []
    # @updated_item = []
    # without_addon_transaction.group_by { |a| [a.itemable_id, a.seat_no] }.each do |key, value|
    #   if(value.length > 1)
    #     total_qty = value.map(&:qty).sum
    #     total_amount = value.map(&:total_amount).sum
    #     first_val = value.shift
    #     first_val.update qty: total_qty, total_amount: total_amount
    #     @deleted_item.push(value.map(&:id))
    #     value.map(&:destroy)
    #     @updated_item.push(first_val);
    #   end
    # end
    # @deleted_item.flatten!
    if pos_transactions.present?
      pos_transactions.each do |pos_transaction|
        pos_transaction.itemable.item_addon_categories.each do |addon_category|
          if addon_category.min_selected_quantity.to_i > 0
            if params[:pos_check_id].present?
              pos_data = PosTransaction.where(pos_check_id: params[:pos_check_id], parent_pos_transaction_id: pos_transaction.id)
            else
              pos_data = PosTransaction.where(pos_table_id: params[:pos_table_id], parent_pos_transaction_id: pos_transaction.id)
            end
            total_count = pos_data.select { |pos| pos.itemable.item_addon_category_id == addon_category.id  }.count
            isValid = total_count >= addon_category.min_selected_quantity.to_i &&  pos_transaction.qty <=  pos_data.select { |pos| pos.itemable.item_addon_category_id == addon_category.id  }.map(&:qty).sum
            @canCountinue.push(isValid)
            @itemId = pos_transaction.itemable_id unless isValid
            @itemName = pos_transaction.item_name unless isValid
          end
        end
      end
    end
    if @menu_item.present?
      @addon_categories = @menu_item.item_addon_categories
      @addon_menu = @addon_categories.map { |a| a.item_addons.where(include_in_pos: true) }.flatten.uniq.compact
    end
    if @menu_item.present? && (params[:pos_table_id].present? || params[:pos_check_id].present?)
      if params[:pos_check_id].present?
        @pos_table_transactions = @menu_item.pos_transactions.where(pos_check_id: params[:pos_check_id])
      else
        @pos_table_transactions = @menu_item.pos_transactions.where(pos_table_id: params[:pos_table_id])
      end
      # if @pos_table_transactions.present?
      #   @pos_transaction = @pos_table_transactions.last
      #   qty = @pos_transaction.qty + params[:qty].to_i
      #   @pos_transaction.assign_attributes(qty: qty, total_amount: @menu_item.price_per_item * qty)
      # else
      branch = Branch.find_by_id(session[:branch_id])
      @pos_transaction = branch.pos_transactions.new(
            itemable: @menu_item,
            qty: params[:qty].to_i == 0 ? 1 : params[:qty].to_i, seat_no: pos_check.order_type_id == 1 ? pos_check&.current_seat_no : '',
            item_name: @menu_item.item_name, item_price: @menu_item.price_per_item,
            total_amount: @menu_item.price_per_item * params[:qty].to_i, pos_table_id: params[:pos_table_id],
            pos_check_id: params[:pos_check_id]
          )
      # end
      unless @canCountinue.include?(false)
        @addon_count = PosTransaction.where(parent_pos_transaction_id: @pos_transaction.id).pluck(:qty).sum
        if @pos_transaction.save
          @success = 'Transaction added.'
        else
          @error = 'Unable to add transaction'
        end
      end
    elsif params[:transaction_id].present?
      @pos_transaction = PosTransaction.find_by(id: params[:transaction_id])
      qty = @pos_transaction.qty + params[:qty].to_i
      @pos_transaction.assign_attributes(qty: qty, total_amount: @pos_transaction.item_price * qty)
      @pos_transaction.save
      @menu_item = @pos_transaction.itemable
    else
      @error = 'Menu Item not found'
    end
    @additional_amount = @menu_item.price_per_item * params[:qty].to_i
    pos_amount_calculation (pos_check)
  end

  def pos_table_seat
    @pos_check = PosCheck.find_by(id: params[:selected_check_id])
    if @pos_check.present?
      # seat_no = @pos_table.current_seat_no.to_i + 1
      # @seat_no = @pos_table.no_of_guest.to_i >= seat_no ? seat_no : 1
      @seat_no = params[:current_seat_number].to_i
      @pos_check.pos_transactions.update_all(transaction_status: 0)
      @pos_check.update(current_seat_no: @seat_no)
    end
  end

  def update_seat_no
    @pos_transaction = PosTransaction.find_by(id: params[:transaction_id])
    if @pos_transaction.present?
      @pos_transaction.update(seat_no: params[:pos_transaction][:seat_no].to_i, transaction_status: 0)
    else
      @error = 'Transaction not found'
    end
  end

  def remove_pos_transaction
    @pos_transaction = PosTransaction.where(id: params['transaction_id'].split(","))
    @pos_check = @pos_transaction&.last&.pos_check
    @qty = []
    @pos_transaction.each do |pos_transaction|
      pos_transaction.addon_pos_transactions.each do |add_on_pos_transaction|
        @qty.push(pos_transaction_qty(add_on_pos_transaction))
      end
    end
    @qty = @qty.flatten.present? ? @qty.to_h.values.sum : 0
    # @pos_transaction.each {|transaction| transaction.addon_pos_transactions.destroy_all }
    @pos_transaction.each {|transaction| transaction.addon_pos_transactions.each {|addon| addon.pos_unsaved_transactions.update_all(is_deleted: true) }}
    @transaction_ids = @pos_transaction.pluck(:id)
    @select_ids = @pos_transaction.map(&:total_amount)
    @isDeleteTransaction = @pos_transaction.present? && @pos_transaction.each {
      |transaction| @pos_check.check_status.eql?('pending') && transaction.pos_unsaved_transactions.length <= 1 ? transaction.destroy : transaction&.pos_unsaved_transactions&.update_all(is_deleted: true) }
    pos_amount_calculation_remove_cash(@pos_check, @transaction_ids)
  end

  def pos_transaction_qty(pos_transaction)
    arr= []
    if pos_transaction.parent_pos_transaction_id.present?
      if params[:menu_item_id].to_i == pos_transaction.parent_pos_transaction.itemable_id && pos_transaction.parent_pos_transaction.itemable_type == 'MenuItem'
        arr.push(pos_transaction.id, pos_transaction.qty)
      end        
    else
      if params[:menu_item_id].to_i == pos_transaction.itemable_id && pos_transaction.itemable_type == 'MenuItem'
        arr.push(pos_transaction.id, pos_transaction.qty)
      end 
    end
    arr
  end

  def clear_pos_transaction
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    pos_table = restaurant.branch.pos_tables.find_by(id: decode_token(params[:table_id]))
    if pos_table.pos_transactions.destroy_all && pos_table.update(current_seat_no: 1)
      @success = 'Transactions cleared successfully'
    else
      @error = 'Unable to clear the transactions'
    end
  end

  def partner_logout
    session[:partner_user_id] = nil
    flash[:success] = "You have successfully signout !"
    redirect_to business_partner_login_path
  end

  def business_earning_graphdata(keyword, restaurant)
    todayDate = Date.today
    case keyword
    when "day"
      @total_income = business_day_earnings("income", todayDate, restaurant)
      @total_orders = business_day_earnings("orders", todayDate, restaurant)
    when "week"
      @total_income = business_week_earnings("income", todayDate, restaurant)
      @total_orders = business_week_earnings("orders", todayDate, restaurant)
    when "month"
      @total_income = business_month_earnings("income", todayDate, restaurant)
      @total_orders = business_month_earnings("orders", todayDate, restaurant)
    when "year"
      @total_income = business_year_earnings("income", todayDate, restaurant)
      @total_orders = business_year_earnings("orders", todayDate, restaurant)
    else
      @total_income = {}
      @total_orders = {}
    end
    result = []
    @total_income.keys.reverse.each do |key|
      graphIncomeItem = {}
      graphIncomeItem["y"] = key
      graphIncomeItem["a"] = @total_income[key]
      graphIncomeItem["b"] = @total_orders[key]
      result << graphIncomeItem
    end
    result
  end

  def business_forget_password
    user = get_user_with_role(params[:email])
    user ||= User.influencer_users.joins(:auths).where(email: params[:email], auths: { role: "customer" }).first

    if user
      update_forget_token(user, user.auths.first.role)
      send_json_response("An OTP has been send to your email", "success", {})
    else
      responce_json(code: 404, message: "User does not exist!")
    end
  end

  def manual_order
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if request.xhr?
      @customers = User.joins(:auths).where(auths: { role: "customer" })
      @contact = params[:search_contact].to_s.squish
      @email = params[:search_email].to_s.squish
      @user_id = params[:searched_user_id]
      @branch = Branch.find_by(id: params[:selected_branch_id])

      if @user_id.present?
        @searched_user = @customers.find(@user_id)
        @addresses = @searched_user.addresses.pluck(:address_name, :id).sort
      elsif @email.present?
        @users = @customers.where(email: @email)
      elsif @contact.present?
        @users = @customers.where("users.contact like ?", "%#{@contact}%")
      end

      render "search_user"
    elsif restaurant
      if @user.auth_role == "business"
        @branches = restaurant.branches.order(:address)
        @restaurants = @user.restaurants.map { |r| [r.title, encode_token(r.id)] }.sort
      else
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:address)
      end
      @areas = CoverageArea.joins(:branches).where(branches: { id: @branches.pluck(:id) }).distinct.pluck(:area, :id).sort
      render layout: "partner_application"
    else
      redirect_to_root
    end
  end

  def create_new_customer_begin_check
    @branch_id = params[:branch_id]
    @note = params[:note]
    area = CoverageArea.find(params[:area_id])
    email = params[:user_email]
    name = params[:user_name]
    country_code = params[:address_contact_number].to_s.gsub(params[:mobile].to_s, "")
    @customer = User.find_by(email: email) || User.create(name: name, email: email, contact: params[:mobile])

    if @customer.auths.blank?
      Auth.create_user_password(@customer, "123456", "customer")
    end

    if params[:address_id].present?
      @address = Address.find(params[:address_id])
      @address.update(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], coverage_area_id: area.id, area: area.area)
    else
      @address = Address.create(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], user_id: @customer.id, coverage_area_id: area.id, area: area.area)
    end
    @branch_coverage_area = BranchCoverageArea.find_by branch_id: @branch_id, coverage_area_id: @address.coverage_area_id
  end

  def create_new_customer_check_id
    @check = PosCheck.find_by id: params[:check_id]
    @branch_id = params[:branch_id]
    @note = params[:note]
    area = CoverageArea.find(params[:area_id])
    email = params[:user_email]
    name = params[:user_name]
    country_code = params[:address_contact_number].to_s.gsub(params[:mobile].to_s, "")
    @customer = User.find_by(email: email) || User.create(name: name, email: email, contact: params[:mobile])

    if @customer.auths.blank?
      Auth.create_user_password(@customer, "123456", "customer")
    end

    if params[:address_id].present?
      @address = Address.find(params[:address_id])
      @address.update(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], coverage_area_id: area.id, area: area.area)
    else
      @address = Address.create(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], user_id: @customer.id, coverage_area_id: area.id, area: area.area)
    end
    @check.update(address_id: @address.id, user_id: @customer.id)
    @branch_coverage_area = BranchCoverageArea.find_by branch_id: @branch_id, coverage_area_id: @address.coverage_area_id
  end

  def place_manual_order(pos_check, amount, payment_method_id)
    @customer = pos_check.user
    if @customer.auths.blank?
      Auth.create_user_password(@customer, "123456", "customer")
    end
    clearCart = clear_cart_deta(@customer.reload.cart)
    params = {}
    pos_transactions = pos_check.pos_transactions.where(itemable_type: 'MenuItem')
    pos_transactions.each_with_index do |transaction, index |
      params["item_id_#{(index+1)}"] = transaction.itemable_id
      params["quantity_#{(index+1)}"] = transaction.qty
      transaction.addon_pos_transactions.each_with_index do |addon_transaction, addon_index |
        params["addon_ids_#{(index+1)}_#{(addon_index+1)}"] = [addon_transaction.itemable_id]
      end
    end
    params.select { |k, _v| k.include?("item_id") }.each do |k, v|
      count = k.split("_")[2]
      item = add_user_cart(@customer.reload, @guestToken, pos_check.branch_id, params["item_id_" + count], params.select { |k, _v| k.include?("addon_ids_" + count) }.values.flatten, params["quantity_" + count], params["description_" + count], pos_check.address.coverage_area_id)
    end

    @user = @customer
    cart = @user ? @user.cart.reload : Cart.find_by(guest_token: @guestToken)
    @area = cart&.coverage_area_id
    carItem = cart&.cart_items
    if carItem.present?
      verifyPayment = verify_payment(@user, @guestToken, params[:transaction_id], pos_check.address_id, params[:pt_transaction_id], params[:pt_token], params[:pt_token_customer_password], params[:pt_token_customer_email], "postpaid", params[:note], params[:is_redeem], false, false)
      if verifyPayment
        order_type = payment_method_id.downcase == 'cash' ? 'postpaid' : 'prepaid'
        verifyPayment.update(pos_check_id: pos_check.id, is_accepted: true, is_rejected: false, accepted_at: DateTime.now, payment_mode: payment_method_id, order_type: order_type, is_paid: (order_type == 'prepaid'))
        clearCart = clear_cart_deta(cart)
        transporter = find_user(pos_check.driver_id)
        if transporter&.status
          order = add_order_transport(@user, verifyPayment.id, transporter.id, amount.to_f)
          if order[:status]
            transporter.update(busy: true)
            orderPushNotificationWorker(@user, order[:user], "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{verifyPayment.id}", verifyPayment.id)
            firebase = firebase_connection
            group = create_track_group(firebase, transporter.id, "26.2285".to_f, "50.5860".to_f)
            stageUpdate = web_update_order_stage(order[:order])
            order_kitchen_pusher(order[:order])
          end
        end
        if @user
          orderPushNotificationWorker(@user, verifyPayment.branch.restaurant.user, "order_created", "Order Created", "Order Id #{verifyPayment.id} is placed by user #{@user.name}", verifyPayment.id)
          orderPusherNotification(@user, verifyPayment)
          send_notification_releted_menu("Order Id #{verifyPayment.id} is placed by user #{@user.name}", "order_created", @user, get_admin_user, verifyPayment.branch.restaurant_id)
        else
          begin
            noti = Notification.create(notification_type: "order_created", message: "Order Id #{verifyPayment.id} is placed by user #{verifyPayment.user.name}", user_id: verifyPayment.user.id, receiver_id: verifyPayment.branch.restaurant.user.id, order_id: verifyPayment.id)
            orderPusherNotification("", verifyPayment)
          rescue Exception => e
          end
        end
      end
    end

  end

  def create_manual_order_cart
    @branch_id = params[:branch_id]
    @note = params[:note]
    area = CoverageArea.find(params[:area_id])
    email = params[:user_email]
    name = params[:user_name]
    country_code = params[:address_contact_number].to_s.gsub(params[:mobile].to_s, "")
    @customer = User.find_by(email: email) || User.create(name: name, email: email)
    @customer.update(contact: params[:address_contact_number])
    if @customer.auths.blank?
      Auth.create_user_password(@customer, "123456", "customer")
    end

    if params[:address_id].present?
      @address = Address.find(params[:address_id])
      @address.update(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], coverage_area_id: area.id, area: area.area)
    else
      @address = Address.create(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], user_id: @customer.id, coverage_area_id: area.id, area: area.area)
    end

    clearCart = clear_cart_deta(@customer.reload.cart)

    params.select { |k, _v| k.include?("item_id") }.each do |k, v|
      count = k.split("_")[2]
       item = add_user_cart(@customer.reload, @guestToken, @branch_id, params["item_id_" + count], params.select { |k, _v| k.include?("addon_ids_" + count) }.values.flatten, params["quantity_" + count], params["description_" + count], area.id)
    end

    @cart_data = cart_list_json(get_cart_item_list(@customer.reload.cart&.reload, request.headers["language"]))
    @total_price = get_cart_item_total_price_checkout(@customer.reload.cart&.reload, false, nil, nil, nil, true, false)
  end

  def create_manual_order
    @customer = User.find(params[:user_id])
    cart = @customer.cart
    @area = cart&.coverage_area_id
    carItem = cart&.cart_items

    if carItem.present?
      verifyPayment = verify_payment(@customer, @guestToken, params[:transaction_id], params[:address_id], params[:pt_transaction_id], params[:pt_token], params[:pt_token_customer_password], params[:pt_token_customer_email], "postpaid", params[:note], false, true, false)

      if verifyPayment
        clearCart = clear_cart_deta(cart)

        if @customer
          orderPushNotificationWorker(@customer, verifyPayment.branch.restaurant.user, "order_created", "Order Created", "Order Id #{verifyPayment.id} is placed by user #{@customer.name}", verifyPayment.id)
          # orderPusherNotification(@customer, verifyPayment)
          send_notification_releted_menu("Order Id #{verifyPayment.id} is placed by user #{@customer.name}", "order_created", @customer, get_admin_user, verifyPayment.branch.restaurant_id)
          verifyPayment.update(on_demand: true, third_party_delivery: true)
          verifyPayment.update(is_accepted: true, is_rejected: false, accepted_at: DateTime.now)
          update_fixed_fc_charge(verifyPayment) if verifyPayment.branch.fixed_charge_percentage.to_f.positive?

          if @user.auth_role == "business"
            redirect_to business_view_order_path(restaurant_id: encode_token(params[:restaurant_id]), id: verifyPayment.id)
            return
          else
            redirect_to business_view_order_path(verifyPayment.id)
            return
          end

        else
          flash[:error] = "Invalid transaction"
        end
      else
        flash[:error] = "Invalid transaction"
      end
    else
      flash[:error] = "Cart Empty"
    end

    rescue Exception => e
  end

  def address_details
    @address = Address.find_by(id: params[:address_id])
  end

  def area_details
    @area = CoverageArea.find_by(id: params[:area_id])
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @user.auth_role == "business"
      @branches = restaurant.branches
    else
      @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id))
    end

    @branches = @branches.joins(:coverage_areas).where(coverage_areas: { id: @area&.id }).distinct
    @selected_branch = @branches.size == 1 ? @branches.first : nil
  end

  def send_customer_order_mail
    @customer = User.find(params[:user_id])
    cart = @customer.reload.cart
    price = get_cart_item_total_price_checkout(cart, false, nil, nil, nil, true, false)
    OrderRequest.create(base_price: price[:sub_total].to_f.round(3), vat_price: price[:total_tax_amount].to_f.round(3), service_charge: price[:delivery_charges].to_f.round(3), total_amount: price[:total_price].to_f.round(3), mobile: @customer.addresses.last&.contact.to_s, branch_id: cart.branch_id, user_id: @customer.id)
    ManualOrderWorker.perform_async(@customer.name, @customer.email, "123456", @customer&.cart&.branch&.restaurant&.title.to_s)
    flash[:success] = "Mail has been successfully sent to Customer"
    redirect_to request.referer
  end

  def requested_orders_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @requests = OrderRequest.joins(:user, :branch).includes(:user, :branch).where(branches: { restaurant_id: restaurant.id })
    else
      @requests = OrderRequest.joins(:user, :branch).includes(:user, :branch).where(branch_id: @user.branch_managers.pluck(:branch_id))
    end

    @branches = Branch.where(id: @requests.pluck(:branch_id)).pluck(:address, :id).sort
    @requests = @requests.where(branch_id: params[:searched_branch_id]) if params[:searched_branch_id].present?
    @requests = @requests.where("DATE(order_requests.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @requests = @requests.where("DATE(order_requests.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @requests = @requests.where("users.name like ? OR users.email = ? OR users.contact = ?", "%#{params[:keyword]}%", params[:keyword], params[:keyword]) if params[:keyword].present?
    @requests = @requests.order(id: :desc)

    respond_to do |format|
      format.html do
        @requests = @requests.order(id: :desc).paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @requests.order_request_list_csv(params[:searched_branch_id], params[:start_date], params[:end_date]), filename: "order_request_list.csv" }
    end
  end

  def show_branch_areas
    @branch = Branch.find_by(id: params[:branch_id])

    if @branch
      @categories = @branch.menu_categories.joins(:menu_items).distinct.pluck(:category_title, :id).sort
    end
  end

  def show_category_items
    @category = MenuCategory.find_by(id: params[:category_id])
    @count = params[:row_id].to_i

    if @category
      @items = @category.menu_items.pluck(:item_name, :id).sort
      @items = @category.menu_items.map { |i| [i.item_name.to_s + " (" + helpers.number_with_precision(i.price_per_item, precision: 3) + ") ", i.id] }.sort
    end
  end

  def show_item_addons
    @item = MenuItem.find_by(id: params[:item_id])
    @count = params[:row_id].to_i

    if @item
      @addon_categories = @item.item_addon_categories.order(:addon_category_name)
    end
  end

  def add_item_row
    @count = params[:row_id].to_i + 1
    @branch = Branch.find_by(id: params[:branch_id])

    if @branch
      @categories = @branch.menu_categories.joins(:menu_items).distinct.pluck(:category_title, :id).sort
    end
  end

  def remove_requested_order
    order_request = OrderRequest.find_by(id: params[:request_id])
    order_request&.destroy
    flash[:success] = "Deleted Successfully!"
    redirect_to request.referer
  end

  def find_branches_based_country
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if @user.auth_role == "business"
      @branches = @restaurant.branches.where(country: params[:country_name])
    else
      @branches = @restaurant.branches.where(country: params[:country_name]).where(id: @user.user_detail&.location&.split(","))
    end
  end

  def set_branch
    session[:branch_id] = params[:location_id]
    redirect_to business_partner_pos_dashboard_terminal_path(restaurant_id: params[:restaurant_id])
  end

  def find_country_based_branch
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:id])
  end

  def pos_dashboard_terminal
    unless session[:branch_id].blank?
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @branch = @restaurant.branches.where(id: session[:branch_id])&.first
    end
    render layout: "partner_application"
  end

  def find_pos_tables
    @branch = Branch.find_by_id(session[:branch_id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @pos_tables = PosTable.where(branch_id: session[:branch_id], floor_name: params[:floor_name])
  end

  private

  def check_branch_status
    Branch.closing_restaurant
    Branch.open_restaurant
    BranchCoverageArea.closing_restaurant_area
    BranchCoverageArea.open_restaurant_area
  rescue ActiveRecord::StatementInvalid => e
  end

  def pos_amount_calculation_remove_cash(pos_check, transaction_ids)
    if pos_check.present?
      unsaved_transactions = @pos_check.pos_unsaved_transactions.includes(:pos_transaction).where(
        'pos_transactions.transaction_status != ?', PosTransaction.transaction_statuses["saved"]).pluck(:pos_transaction_id)
      unsaved_transactions = unsaved_transactions.push(transaction_ids).flatten.compact.uniq
      total_amt = pos_check.reload.pos_transactions.where.not(id: unsaved_transactions)&.pluck(:total_amount)&.sum.to_f
      @tax_amount = taxonlyamount(5, total_amt)
      @sub_total = total_amt - @tax_amount
      offer = pos_check.offer
      if offer.present?
        discount_percent = offer.discount_percentage.to_f == 0.0 && offer.offer_title.eql?('Buy 1 Get 1 Free') ? 50 : offer.discount_percentage.to_f
        addons = ItemAddon.where(item_addon_category_id: offer.menu_item.item_addon_categories.pluck(:id)) if offer.menu_item_id.present?
        transactions_amount = offer.offer_type.eql?('individual') ? pos_check.pos_transactions.where(
          '((itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?))) && id NOT IN (?)',
          "MenuItem", offer.menu_item_id, "ItemAddon", addons.pluck(:id), unsaved_transactions )&.pluck(:total_amount)&.sum.to_f : total_amt
        transaction_tax = taxonlyamount(5, transactions_amount)
        @discount = (transactions_amount.to_f - transaction_tax.to_f) * discount_percent / 100
      else
        @discount = 0.0
      end
      @total_amount = total_amt - pos_check.pos_payments.where(pending_delete: false).pluck(:paid_amount).sum - @discount
    else
      @tax_amount = 0.0
      @sub_total = 0.0
      @discount = 0.0
      @total_amount = 0.0
    end
  end

  def pos_amount_calculation(pos_check)
    if pos_check.present?
      total_amt = pos_check.reload.pos_transactions&.pluck(:total_amount)&.sum.to_f
      @tax_amount = taxonlyamount(5, total_amt)
      @sub_total = total_amt - @tax_amount
      offer = pos_check.offer
      if offer.present?
        discount_percent = offer.discount_percentage.to_f == 0.0 && offer.offer_title.eql?('Buy 1 Get 1 Free') ? 50 : offer.discount_percentage.to_f
        addons = ItemAddon.where(item_addon_category_id: offer.menu_item.item_addon_categories.pluck(:id)) if offer.menu_item_id.present?
        transactions_amount = offer.offer_type.eql?('individual') ? pos_check.pos_transactions.where(
          '((itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?)))',
          "MenuItem", offer.menu_item_id, "ItemAddon", addons.pluck(:id) )&.pluck(:total_amount)&.sum.to_f : total_amt
        transaction_tax = taxonlyamount(5, transactions_amount)
        @discount = (transactions_amount.to_f - transaction_tax.to_f) * discount_percent / 100
      else
        @discount = 0.0
      end
      @total_amount = total_amt - pos_check.pos_payments.where(pending_delete: false).pluck(:paid_amount).sum - @discount
    else
      @tax_amount = 0.0
      @sub_total = 0.0
      @discount = 0.0
      @total_amount = 0.0
    end
  end
end
