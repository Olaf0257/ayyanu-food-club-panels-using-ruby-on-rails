module Business::OffersHelper
  def get_restaurant_advertisement(restaurant, ad_type)
    Advertisement.where(place: (ad_type.presence || "list")).find_restaurant_advertisement(restaurant)
  end

  def get_restaurant_offers(branches)
    Offer.find_restaurant_offers(branches)
  end

  def get_branch_offer_list(branch)
    Offer.find_branch_offer(branch).paginate(page: params[:page], per_page: params[:per_page])
  end

  def get_branch_menu(branch)
    MenuItem.includes(:menu_category, :item_addon_categories).where(menu_category_id: branch.menu_categories.pluck(:id))
  end

  def add_branch_menu_offer(branch, offer_title, start_date, end_date, menu_item, discount_percentage, offer_image, offer_type)
    url = offer_image.present? ? upload_multipart_image(offer_image, "advertisement") : ""
    Offer.offer_menu_item(branch, offer_title, start_date, end_date, menu_item, discount_percentage, url, offer_type)
  end

  def update_branch_menu_offer(offer, branch, offer_title, start_date, end_date, menu_item, discount_percentage, offer_image, offer_type)
    prev_img = offer.offer_image.present? ? offer.offer_image.split("/").last : "n/a"
    url = offer_image.present? ? update_multipart_image(prev_img, offer_image, "advertisement") : offer.offer_image
    offer.update(discount_percentage: discount_percentage, start_date: start_date + " " + Time.now.strftime("%H:%M:%S"), end_date: end_date + " " + Time.now.strftime("%H:%M:%S"), offer_title: offer_title, branch_id: branch.id, menu_item_id: offer_type == "all" ? "" : menu_item, offer_image: url, offer_type: offer_type)
  end

  def get_menu_offer(offer_id)
    Offer.find_menu_offer(offer_id)
  end

  def get_pending_ads_data(user, restaurant, ad_type)
    AddRequest.where(place: (ad_type.presence || "list")).find_all_ads(user, restaurant)
  end

  def update_pending_offer_record(offer, position, place, title, description, amount, week_id, branch_id, coverage_area_id, branch_image)
    prev_img = offer.image.present? ? offer.image.split("/").last : "n/a"
    url = branch_image.present? ? update_multipart_image(prev_img, branch_image, "advertisement") : offer.image
    offer.update(position: position, place: place, title: title, description: description, amount: amount, week_id: week_id, branch_id: branch_id, coverage_area_id: coverage_area_id, image: url)
  end
end
