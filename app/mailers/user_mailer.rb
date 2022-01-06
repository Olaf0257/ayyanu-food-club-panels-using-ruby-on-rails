class UserMailer < ApplicationMailer
  def forget_password(user, auth)
    @user = user
    @auth = auth
    @name = user.name
    @token = @user.auths.first.reset_password_token
    mail(to: @user.email, subject: "Food Club forgot password link")
  end

  def send_email_new_menu_item(business_user, title, msg)
    @user = business_user
    @title = title
    @msg = msg
    email = SuperAdmin.first.email
    mail(to: email, subject: @title)
  end

  def send_email_on_approve_user(email, name, password)
    @email = email
    @name = name
    @password = password
    mail(to: @email, subject: "Food Club join")
  end

  def send_approve_email(email, name, password)
    @email = email
    @user_name = name
    @password = password
    mail(to: @email, subject: "Influencer Approved by Food Club")
  end

  def contract_expiry_email(email, name, end_date)
    @email = email
    @user_name = name
    @end_date = end_date
    mail(to: @email, subject: "Food Club Contract Expiration")
  end

  def send_manual_order_mail(name, email, password, restaurant)
    @email = email
    @user_name = name
    @password = password
    mail(to: @email, subject: "Thank you for placing order with #{restaurant}")
  end

  def send_influencer_coupon_email(coupon_id)
    @coupon = InfluencerCoupon.find(coupon_id)
    @email = @coupon.user.email
    @name = @coupon.user.name
    mail(to: @email, subject: "Food Club Coupon Details")
  end

  def send_referral_coupon_email(coupon_id, user_id, referrer)
    @coupon = ReferralCoupon.find(coupon_id)
    @email = User.find(user_id).email
    @name = User.find(user_id).name
    @referrer = referrer
    mail(to: @email, subject: "Food Club Coupon Details")
  end

  def send_restaurant_coupon_email(coupon_id, restaurant_id)
    @coupon = RestaurantCoupon.find(coupon_id)
    @restaurant = Restaurant.find(restaurant_id)
    @email = @restaurant.user.email
    @name = @restaurant.user.name
    mail(to: @email, subject: "Food Club Promo Code Details")
  end

  def user_point_expiry_email(user, points, expiry_date)
    @email = user.email
    @user_name = user.name
    @points = points
    @expiry_date = expiry_date
    mail(to: @email, subject: "Food Club Points Expiry Reminder")
  end

  def influencer_point_selling_email(user_id, restaurant_id)
    @user = User.find(user_id)
    @email = @user.email
    @user_name = @user.name
    @restaurant = Restaurant.find(restaurant_id)
    mail(to: @email, subject: "Food Club Party Points Sold")
  end

  def cart_details_mail(cart_id)
    @cart = Cart.find(cart_id)
    @user = @cart.user
    @email = @user.email
    @name = @user.name
    mail(to: @email, subject: "Food Club Cart Details")
  end
end
