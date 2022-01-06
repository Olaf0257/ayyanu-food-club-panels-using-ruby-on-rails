class Business::DocumentsController < ApplicationController
  before_action :authenticate_business
  def document_list
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if @restaurant
      @documents = @restaurant.restaurant_document
      @restaurant_contract = get_admin_doc("contract")
      render layout: "partner_application"
    else
      redirect_to_root
    end
  end
end
