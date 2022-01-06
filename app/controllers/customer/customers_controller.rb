class Customer::CustomersController < ApplicationController
  before_action :authenticate_customer
  before_action :check_point_expired_date

  def dashboard
    unless @user
      session[:guest_token] = nil
      @guest_user = User.find_by(email: @guestToken + "@foodclube.com")
      @orders = @guest_user.orders.order(id: :desc).paginate(page: params[:page], per_page: 10)
    else
      @clubs = ClubCategory.joins(:club_sub_categories).order("club_categories.id DESC").distinct
      @user.update(referral: "#{@user.name.first(1)}#{@user.id}#{@user.email.first(5)}") if @user.referral.blank?
      @favorite_branches = Branch.where(id: @user.favorites.pluck(:branch_id))
      @offers = Offer.active.running.joins(branch: :restaurant).where(restaurants: { country_id: session[:country_id], is_signed: true }, branches: { is_approved: true }).distinct
      @points = Point.find_user_point(@user, nil, nil, nil)
      @orders = @user.orders.order(id: :desc).paginate(page: params[:page], per_page: 10)
      @addresses = @user.addresses
      @referrals = @user.referrals.select { |r| User.find_by(email: r.email).present? }
    end
  end

  def point_details
    @branch_id = params[:branch_id]
    @branch = Branch.find(@branch_id)
    @points = Point.where(user_id: @user.id, branch_id: @branch_id).order(id: :desc)
    @total_point = branch_available_point(@user.id, @branch_id)
  end

  def order_details
    @order = Order.find(params[:order_id])
  end

  def add_user_club
    user_id = params[:user_id]
    category_id = params[:category_id]

    if params[:status] == "join"
      UserClub.find_or_create_by(user_id: user_id, club_sub_category_id: category_id)
    else
      UserClub.find_by(user_id: user_id, club_sub_category_id: category_id)&.destroy
    end

    render json: { code: 200 }
  end

  def new_guest_address
  end

  def add_guest_address
    @user = add_guest_user(@guestToken, params[:first_name], params[:last_name])
    address = Address.new(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], contact: params[:mobile], landline: params[:landline], user_id: @user.id, country_code: (params[:full_phone_contact].gsub(params[:mobile].split(" ").join(""), "")), location: params[:location], latitude: params[:latitude], longitude: params[:longitude])

    area_ids = get_coverage_area_from_location(params[:latitude].to_f, params[:longitude].to_f)
    all_areas = CoverageArea.where(id: area_ids)
    selected_area_id = all_areas.select { |a| params[:location].to_s.squish.downcase.include?(a.area.downcase) }.first&.id
    address.coverage_area_id = selected_area_id.presence || area_ids.first

    if params[:coverage_area_id].to_i != address.coverage_area_id.to_i
      @user&.destroy
      flash[:error] = "Selected location is outside " + CoverageArea.find(params[:coverage_area_id])&.area.to_s + " Area"
    elsif address.save
      @user.cart&.destroy
      Cart.find_by(guest_token: @guestToken).update(user_id: @user.id)
      flash[:success] = "Address Successfully Added!"
    else
      flash[:error] = address.errors.full_messages.first.to_s
    end

    redirect_to customer_cart_item_list_path
  end

  def edit_guest_address
    @address = Address.find(params[:address_id])
  end

  def update_guest_address
    @address = Address.find(params[:address_id])

    area_ids = get_coverage_area_from_location(params[:latitude].to_f, params[:longitude].to_f)
    all_areas = CoverageArea.where(id: area_ids)
    selected_area_id = all_areas.select { |a| params[:location].to_s.squish.downcase.include?(a.area.downcase) }.first&.id
    @address.coverage_area_id = selected_area_id.presence || area_ids.first

    if params[:coverage_area_id].to_i != @address.coverage_area_id.to_i
      flash[:error] = "Selected location is outside " + CoverageArea.find(params[:coverage_area_id])&.area.to_s + " Area"
    else
      @address.update(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], contact: params[:mobile], landline: params[:landline], country_code: (params[:full_phone_contact].present? ? params[:full_phone_contact].gsub(params[:mobile].split(" ").join(""), "") : @address.country_code), location: params[:location], latitude: params[:latitude], longitude: params[:longitude])
      flash[:success] = "Address Successfully Updated!"
    end

    redirect_to customer_cart_item_list_path
  end

  def new_address
  end

  def add_address
    address = Address.new(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], contact: params[:mobile], landline: params[:landline], user_id: @user.id, country_code: (params[:full_phone_contact].gsub(params[:mobile].split(" ").join(""), "")), location: params[:location], latitude: params[:latitude], longitude: params[:longitude])
    area_ids = get_coverage_area_from_location(params[:latitude].to_f, params[:longitude].to_f)
    all_areas = CoverageArea.where(id: area_ids)
    selected_area_id = all_areas.select { |a| params[:location].to_s.squish.downcase.include?(a.area.downcase) }.first&.id
    address.coverage_area_id = selected_area_id.presence || area_ids.first

    if address.save
      flash[:success] = "Address Successfully Added!"
    else
      flash[:error] = address.errors.full_messages.first.to_s
    end

    redirect_to customer_dashboard_path
  end

  def edit_address
    @address = Address.find(params[:address_id])
  end

  def update_address
    @address = Address.find(params[:address_id])
    area_ids = get_coverage_area_from_location(params[:latitude].to_f, params[:longitude].to_f)
    all_areas = CoverageArea.where(id: area_ids)
    selected_area_id = all_areas.select { |a| params[:location].to_s.squish.downcase.include?(a.area.downcase) }.first&.id
    @address.coverage_area_id = selected_area_id.presence || area_ids.first

    if @address.update(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], contact: params[:mobile], landline: params[:landline], country_code: (params[:full_phone_contact].gsub(params[:mobile].split(" ").join(""), "")), location: params[:location], latitude: params[:latitude], longitude: params[:longitude])
      flash[:success] = "Address Successfully Updated!"
    else
      flash[:error] = @address.errors.full_messages.first.to_s
    end

    redirect_to customer_dashboard_path
  end

  def fill_address
    latitude = params[:latitude]
    longitude = params[:longitude]

    if latitude.present? && longitude.present?
      result = get_here_api_location_details(latitude, longitude)

      if result.present? && result["address"].present?
        @block = result["address"]["district"]
        @road = result["address"]["street"]
        @building = result["address"]["houseNumber"]
      end
    end
  end

  def add_favorite_branch
    branch_id = params[:branch_id]
    user_id = params[:user_id]
    favorite = Favorite.new(user_id: user_id, branch_id: branch_id)

    if favorite.save
      render json: { code: 200 }
    else
      render json: { code: 404 }
    end
  end

  def remove_favorite_branch
    branch_id = params[:branch_id]
    user_id = params[:user_id]
    favorite = Favorite.find_by(user_id: user_id, branch_id: branch_id)&.destroy
    render json: { code: 200 }
  end

  def signup
    if current_user
      flash[:warning] = "Already logged in"
      redirect_to root_path
      return
    end

    @user = User.new
    render layout: "blank"
  end

  def create_customer
    if params[:referrer_id].present?
      @referrer = User.find_by(referral: params[:referrer_id])

      if @referrer && params[:email].present?
        alreadyExists = Referral.where(email: params[:email]).first

        if !alreadyExists
          @referrer.referrals.create(email: params[:email])
        else
          alreadyExists.update(user_id: @referrer.id) unless alreadyExists.is_registered
        end
      end
    end

    @user = User.new(name: params[:name], email: params[:email], user_name: params[:user_name], country_code: (params[:full_phone_contact].gsub(params[:contact].split(" ").join(""), "")), contact: params[:contact], country_id: params[:country_id])

    if @user.save
      image = params[:image].present? ? upload_multipart_image(params[:image], "user") : nil
      @user.update(image: image)
      auth = Auth.create_user_password(@user, params[:password], "customer")

      referral = Referral.find_by(email: @user.email)
      referral_coupon = ReferralCoupon.where("DATE(start_date) <= ? AND DATE(end_date) >= ?", Time.zone.today, Time.zone.today).first

      if referral && referral_coupon
        ReferralCouponUser.create(referral_coupon_id: referral_coupon.id, user_id: @user.id, referrer: false)
        ReferralCouponWorker.perform_async(referral_coupon.id, @user.id, false)
        ReferralCouponUser.create(referral_coupon_id: referral_coupon.id, user_id: referral.user_id, referrer: true)
        ReferralCouponWorker.perform_async(referral_coupon.id, referral.user_id, true)
      end

      auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      flash[:success] = "Successfully Registered !"
      redirect_to root_path
    else
      flash[:error] = @user.errors.full_messages.first.to_s
      redirect_to request.referer
    end
  end

  def update_customer
    auth = @user.auths.find_by(role: "customer")

    if @user.update(name: params[:name], user_name: params[:user_name], email: params[:email], contact: params[:contact], country_id: params[:country_id], country_code: (params[:full_phone_contact].gsub(params[:contact].split(" ").join(""), "")))
      image = params[:image].present? ? upload_multipart_image(params[:image], "user") : @user.image
      @user.update(image: image)
      auth.update(password: params[:password]) if params[:password].present?
      flash[:success] = "Successfully Updated Account !"
    else
      flash[:error] = @user.errors.full_messages.first.to_s
    end

    redirect_to customer_dashboard_path
  end

  def login
    render layout: "blank"
  end

  def customer_auth
    if params[:email].present? && params[:password].present?
      user = User.find_by(email: params[:email])

      if user
        @auth = user.auths.where(role: "customer").first
        session[:customer_user_id] = nil if session[:customer_user_id].present?

        if user && (@auth ? @auth.valid_password?(params[:password]) : false)
          server_session = @auth.server_sessions.create(server_token: @auth.ensure_authentication_token)
          session[:customer_user_id] = server_session.server_token
          flash[:success] = "Logged In Successfully!"

          if params[:guest_token].present?
            user.cart&.destroy
            Cart.find_by(guest_token: params[:guest_token]).update(user_id: user.id, guest_token: nil)
            redirect_to customer_cart_item_list_path
          else
            redirect_to root_path
          end
        else
          flash[:error] = "Unauthorised Access !!"
          redirect_to customer_customer_login_path(guest_token: params[:guest_token])
        end
      else
        flash[:error] = "Unauthorised Access !!"
        redirect_to customer_customer_login_path(guest_token: params[:guest_token])
      end
    else
      flash[:error] = "Email and password can't be blank"
      redirect_to customer_customer_login_path(guest_token: params[:guest_token])
    end
  end

  def logout
    session[:customer_user_id] = nil
    flash[:success] = "You have successfully signed out!"
    redirect_to root_path
  end

  def forgot_password
    user = User.joins(:auths).where(email: params[:email], auths: { role: "customer" }).first

    if user
      update_forget_token(user, user.auths.first.role)
      send_json_response("An OTP has been send to your email", "success", {})
    else
      responce_json(code: 404, message: "User does not exist!")
    end
  end

  def send_otp
    @address = Address.find(params[:address_id])
    user = @address.user
    branch_country_code = user.cart.branch.contact.first(@address.country_code.to_s.length)

    if @address.country_code.to_s != branch_country_code.to_s
      flash.now[:error] = "Only Card Payments will be accepted as this Contact number is outside the Restaurant Country."
    elsif user && @address.contact.present? && @address.country_code.present?
      otp = format("%04d", Random.rand(1000..9999))
      auth = user.auths.find_by(role: "customer")
      auth&.update(otp: otp)
      @contact_number = @address.country_code + @address.contact

      if Rails.env.production?
        account_sid = Rails.application.secrets["twilio_account_sid"]
        auth_token = Rails.application.secrets["twilio_auth_token"]
        from = Rails.application.secrets["twilio_number"]
        to = @contact_number
        @client = Twilio::REST::Client.new(account_sid, auth_token)
        @client.messages.create(from: from, to: to, body: "Your Food Club OTP for Placing Order is #{otp}")
      end

      flash.now[:success] = "An OTP has been send to your Mobile Number"
    else
      flash.now[:error] = "Contact number or Country Code not present for the selected address. Please Add."
    end
  end

  def verify_otp
    user = User.find(params[:user_id])
    auth = user.auths.find_by(role: "customer")
    @otp = params[:otp].squish

    if auth.otp == @otp.to_s
      flash[:success] = "OTP Successfully Verified"
    else
      flash[:error] = "OTP did not match"
    end
  end

  private

  def check_point_expired_date
    Point.where(expired_date: nil).each do |point|
      point.update(expired_date: (point.created_at + 6.months))
    end
  end
end
