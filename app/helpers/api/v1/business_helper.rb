module Api::V1::BusinessHelper
  def find_user_iou(user)
    user = find_user(user)
    role = get_user_auth(user, "transporter")
    role ? Iou.update_iou_list(user) : false
  end

  def iou_list_data(iou_list)
    # sum =0
    # arr =[]
    # list = iou_list.pluck(:transporter_id).uniq
    # list.map do |e|
    #   iou = iou_list.where("transporter_id=?",e)
    #   sum = iou.inject(0) {|sum, hash| sum + hash[:paid_amount]}
    #   iou_hash = iou.last.as_json(:only=>[:is_received],include: [:transporter=>{:only=>[:id,:name,:image]} ]).merge(:paid_amount=>sum)
    #   arr<<iou_hash
    # end
    # arr
    iou_list.as_json(include: [transporter: { only: [:id, :name, :image] }])
  end

  def adds_show_json(adds)
    adds.as_json(include: [{ branch: { only: [:id, :address], methods: [:discount, :branch_menus, :avg_rating], include: [restaurant: { only: [:id, :title, :logo] }] } }, { week: { only: [:id, :start_date, :end_date] } }, coverage_area: { only: [:id, :area] }])
  end

  def branch_json_data(branch)
    branch.as_json(only: [:id, :address])
  end

  def find_iou(iou_id)
    Iou.find(iou_id)
  end

  def find_week(week_id)
    Week.get_week(week_id)
  end

  def find_beginning_week
    date = Date.today.at_beginning_of_week(start_day = :sunday)
  end

  def week_data(country_id)
    Week.where("extract(year from start_date) = ? AND country_id = ?", Date.today.year, country_id)
  end

  def find_business_branches(user)
    Restaurant.restaurant_branches(user.id)
  end

  def find_area(area_id)
    CoverageArea.get_area(area_id)
  end

  def find_adds_req(adds_id)
    AddRequest.get_adds_req(adds_id)
  end

  def new_adds_request(position, place, title, description, amount, week_id, branch_id, coverage_area_id, branch_image)
    url = branch_image.present? ? upload_multipart_image(branch_image, "advertisement") : ""
    AddRequest.create_adds_request(position, place, title, description, amount, week_id, branch_id, coverage_area_id, url)
  end

  def find_business_offers(user)
    branches = find_business_branches(user)
    branch_id = branches ? branches.branches ? branches.branches.pluck(:id) : [] : []
    find_branchId(branch_id)
  end

  def find_branchId(branch_id)
    Advertisement.get_branchId(branch_id)
  end

  def find_business_offer(offer_id, restaurant_id)
    Advertisement.get_business_offer(offer_id, restaurant_id)
  end

  def advertisement_status(offers)
    result = []
    offers.each do |a|
      if (a.from_date > Date.today) && (a.to_date > Date.today)
        status = "UPCOMING"
        time_left = (a.from_date - Date.today) # .strftime("%H:%M:%S")
      elsif (a.from_date <= Date.today) && (a.to_date >= Date.today)
        status = "RUNNING"
        time_left = nil
      else
        status = "NOT APPLICABLE"
        time_left = nil
      end
      a["status"] = status
      # time_left =time_left
      result << a.as_json.merge(branch_name: a.branch.address, time_left: time_left)
    end
    result
  end

  def delete_business_offer(offer_id, user)
    offer = find_business_offer(offer_id, user.restaurant.id)
    if offer
      offer.destroy
      { status: true }
    else
      { status: false }
    end
  end
end
