class SessionsController < ApplicationController
  def google_auth
    access_token = request.env["omniauth.auth"]
    user = User.from_omniauth(access_token)

    if user
      user.google_token = access_token.credentials.token
      refresh_token = access_token.credentials.refresh_token
      user.google_refresh_token = refresh_token if refresh_token.present?

      if user.save && user.auths.empty?
        auth = Auth.new
        auth.user_id = user.id
        auth.role = "customer"
        auth.save(validate: false)
        auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      end
    end

    if user.save && user.auths.find_by(role: "customer").present?
      auth = user.auths.where(role: "customer").first
      session[:customer_user_id] = nil if session[:customer_user_id].present?
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:customer_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully!"
    else
      flash[:error] = "User already present with this email"
    end

    redirect_to root_path
  end

  def facebook_auth
    access_token = request.env["omniauth.auth"]
    user = User.from_omniauth(access_token)

    if access_token&.info&.email.nil?
      flash[:error] = "No Email present in this Facebook account"
      redirect_to root_path
      return
    end

    if user && user.auths.empty? && user.save
      auth = Auth.new
      auth.user_id = user.id
      auth.role = "customer"
      auth.save(validate: false)
      auth.server_sessions.create(server_token: auth.ensure_authentication_token)
    end

    if user.save && user.auths.find_by(role: "customer").present?
      auth = user.auths.where(role: "customer").first
      session[:customer_user_id] = nil if session[:customer_user_id].present?
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:customer_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully!"
    else
      flash[:error] = "User already present with this email"
    end

    redirect_to root_path
  end

  def instagram_auth
    access_token = request.env["omniauth.auth"]
    user = User.from_omniauth(access_token)

    if access_token&.info&.email.nil?
      flash[:error] = "No Email present in this Instagram account"
      redirect_to root_path
      return
    end

    if user && user.auths.empty? && user.save
      auth = Auth.new
      auth.user_id = user.id
      auth.role = "customer"
      auth.save(validate: false)
      auth.server_sessions.create(server_token: auth.ensure_authentication_token)
    end

    if user.save && user.auths.find_by(role: "customer").present?
      auth = user.auths.where(role: "customer").first
      session[:customer_user_id] = nil if session[:customer_user_id].present?
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:customer_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully!"
    else
      flash[:error] = "User already present with this email"
    end

    redirect_to root_path
  end
end