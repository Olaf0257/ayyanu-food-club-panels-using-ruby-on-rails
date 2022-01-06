class Api::Web::NewRestaurantRequestsController < Api::ApiController
  before_action :validate_request
  def new_restaurant_request
    # begin
    restaurant = add_restaurant_request(params[:restaurant_name], params[:restaurant_id], params[:person_name], params[:contact_number], params[:role], params[:email], params[:area], params[:cuisine], params[:cr_number], params[:bank_name], params[:bank_account], params[:images], params[:signature], params[:cpr_number], params[:owner_name], params[:nationality], params[:submitted_by], params[:delivery_status], params[:branch_no], params[:mother_company_name], params[:serving], params[:block], params[:road_number], params[:building], params[:unit_number], params[:floor], params[:other_name], params[:other_role], params[:other_email], params[:country_id])
    if restaurant
      @admin = get_admin_user
      msg = "#{restaurant.restaurant_name} restaurant has request to join Food Club"
      type = "request_new_restaurant"
      send_notification_releted_menu(msg, type, "", @admin, restaurant.id)
      responce_json(code: 200, message: "Your request submitted successfully.")
    else
      responce_json(code: 422, message: "Invalid request!!")
    end
      # rescue Exception => e
      #   responce_json({:code=>422, :message=>"#{e}"})
      # end
    end

  private

  def validate_request
    role = %w[business manager other]
    validateRole = role.include? params[:role]
    unless params[:restaurant_name].present? && params[:person_name].present? && params[:contact_number].present? && validateRole && params[:email].present? && params[:area].present? && params[:cuisine].present? && params[:images].present?
      responce_json(code: 422, message: "Please enter required parameter!!")
     end
      end
end
