module Api::Web::UsersHelper
  def get_user_total_point(user)
    helpers.number_with_precision(user.points.where("point_type = (?)", "Credit").pluck(:user_point).sum, precision: 3)
  end

  def user_email_and_role(email, role)
    User.joins(:auths).where("role = ? and email = ? ", role, email).first
  end

  # def user_email email,role
  # User.joins(:auths).where("email = (?) and role = ?",email,role)
  # end

  # def update_forget_token user,role
  #   auth = User.update_token(user,role)
  #   send_forget_password_email(user,auth)
  # end
end
