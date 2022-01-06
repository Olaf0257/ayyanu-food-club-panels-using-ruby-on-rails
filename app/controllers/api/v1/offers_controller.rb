class Api::V1::OffersController < Api::ApiController
  before_action :validate_offer, only: [:add_offer]
  def offer_list
    offers = get_offers_list(params[:area_id], params[:page], params[:per_page])
    if offers
      responce_json(code: 200, message: "Offers list.", offers: offer_json(offers))
    else
      responce_json(code: 404, message: "Offer not found!!")
    end
    end

  def add_offer
    offer = add_branch_offer(params[:branch_id], params[:menu_item_id], params[:offer_type], params[:discount_percentage], params[:start_date], params[:end_date], params[:offer_title])
    if offer
      responce_json(code: 200, message: "Offers added successfully.", offer: offer)
    else
      responce_json(code: 404, message: "Offer not added!!")
    end
    end

  def offer_branch_area
    offer = get_offer(params[:offer_id], request.headers["language"])
    responce_json(code: 200, message: "Offers data successfully.", offer_areas: offer ? offer : [])
    rescue Exception => e
  end

  private

  def validate_offer
    branch = get_restaurant_branch(params[:branch_id])
    item = get_branch_menu_item(branch, params[:menu_item_id]) if branch && params[:menu_item_id]
    unless ((params[:offer_type] == "all") && branch && params[:discount_percentage].present? && params[:start_date].present? && params[:end_date].present? && params[:offer_title].present?) || ((params[:offer_type] == "individual") && branch && params[:discount_percentage].present? && params[:start_date].present? && params[:end_date].present? && params[:offer_title].present? && params[:menu_item_id].present? && item)
      responce_json(code: 422, message: "Required parameter messing!!")
     end
      end
end
