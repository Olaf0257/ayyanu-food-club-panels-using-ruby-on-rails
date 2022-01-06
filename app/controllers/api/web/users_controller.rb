class Api::Web::UsersController < Api::ApiController
  before_action :authenticate_api_access, only: [:web_user_details]
  def web_user_details
    if @user
      pointsData = Point.find_user_point(@user, 1, 100, "")
      responce_json(code: 200, message: "User successfully", user: @user.as_json.merge(total_point: pointsData[:totalPoint]))
    else
      responce_json(code: 404, message: "User does not exist!")
     end
   end

  def validate_email
    business_email = user_email_and_role(params[:email], "business")
    user_email = User.find_by(email: params[:email])
    status = business_email.present? ? false : user_email.present? ? true : false
    responce_json(code: 200, email: status, message: "Email already exists. Please choose a different email!!")
   end

  def web_forgot_password
    user = user_email_and_role(params[:email], "customer")
    if user.present?
      # update_forget_token(user,"customer")
      responce_json(code: 200, message: "User exists!")
    else
      responce_json(code: 404, message: "User does not exist!")
    end
  rescue StandardError
    responce_json(code: 422, message: "Invalid request!")
  end
end
