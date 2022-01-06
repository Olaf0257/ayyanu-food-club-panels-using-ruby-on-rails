module OffersHelper
  def find_week_offers
    date1 = find_beginning_week
    date2 = find_end_week
    AddRequest.get_week_offers(date1, date2)
  end

  def find_end_week
    Date.today.at_end_of_week(start_day = :sunday)
  end

  def find_place_offers(position)
    AddRequest.get_place_offers(position, @admin)
  end

  def add_request_action(add_id)
    add_req = find_adds_req(add_id)
    add = add_req ? Advertisement.create_advertisement(add_req.branch.restaurant_id, add_req.place, add_req.position, add_req.title, add_req.description, add_req.amount, add_req.week.start_date, add_req.week.end_date, add_req.id, add_req.branch_id, add_req.image) : false
    req = add ? add_req.update(is_accepted: true) : false
    req ? { status: true, req: add } : { status: false, req: "" }
  end

  def get_all_advertisement_list(ad_type, keyword, status, start_date, end_date)
    advertisements = Advertisement.where(place: (ad_type.presence || "list")).find_all_advertisement_list(@admin)
    advertisements = advertisements.where("DATE(advertisements.created_at) >= ?", start_date.to_date) if start_date.present?
    advertisements = advertisements.where("DATE(advertisements.created_at) <= ?", end_date.to_date) if end_date.present?
    advertisements = advertisements.joins(:branch, :restaurant).where("restaurants.title like ? OR branches.address like ?", "%#{keyword}%", "%#{keyword}%") if keyword.present?
    advertisements = advertisements.where("DATE(advertisements.from_date) <= ? AND DATE(advertisements.to_date) > ?", Date.today, Date.today) if status.to_s == "Running"
    advertisements = advertisements.where("DATE(advertisements.from_date) > ?", Date.today) if status.to_s == "Upcoming"
    advertisements = advertisements.where("DATE(advertisements.to_date) < ?", Date.today) if status.to_s == "Closing"

    advertisements.distinct.order(id: :desc)
  end

  def rejected_add_list(ad_type)
    AddRequest.where(place: (ad_type.presence || "list")).find_all_reject_list(@admin)
  end
end
