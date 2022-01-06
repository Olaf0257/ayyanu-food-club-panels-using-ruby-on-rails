module Api::V1::OffersHelper
  def offer_json(offers)
    offers.as_json(include: { menu_item: branche_menu_item_except_attributes })
  end

  def get_offers_list(area_id, page, per_page)
    if area_id.present?
      Offer.find_offers_list(area_id, page, per_page)
    else
      Offer.find_all_offers_list(page, per_page)
    end
  end

  def add_branch_offer(branch_id, menu_item_id, offer_type, discount_percentage, start_date, end_date, offer_title)
    Offer.add_new_offer(branch_id, menu_item_id, offer_type, discount_percentage, start_date, end_date, offer_title)
  end

  def get_offer(offer, language)
    Offer.find_offers(offer, language)
  end
end
