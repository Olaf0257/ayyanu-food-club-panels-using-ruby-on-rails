module Api::V1::TransportersHelper
  def iou_list_json(iou_list)
    iou_list.as_json(include: [transporter: { only: [:id, :name, :image] }])
  end

  def get_user_lat_log(latitude, longitude, user)
    user.update(latitude: latitude, longitude: longitude)
  end

  def update_active_status(user)
    status = user.status != true
    user.update(status: status) if user.is_approved.present?

    if status
      TransporterTiming.create(user_id: user.id, login_time: DateTime.now) unless user.delivery_company&.active == false
    else
      unless user.delivery_company&.active == false
        last_timing = TransporterTiming.where(user_id: user.id).last
        last_timing.present? ? last_timing.update(logout_time: DateTime.now) : TransporterTiming.create(user_id: user.id, logout_time: DateTime.now)
      end
    end
  end

  def get_iou_list(user, branch, page, per_page)
    role = user.auths.first.role
    if role == "business"
      branch = get_branch_data(branch)
      userId = BranchManager.where(branch_id: branch.id).pluck(:user_id)
      user_id = userId << user.id
      Iou.where("user_id IN (?) and is_received = ? and (DATE(updated_at) > ? and DATE(updated_at) <= ?)", user_id, false, Date.today - 3, Date.today).order(id: "DESC").paginate(page: page, per_page: per_page)
    else
      Iou.where("user_id = ? and is_received = ? and (DATE(updated_at) > ? and DATE(updated_at) <= ?)", user.id, false, Date.today - 3, Date.today).order(id: "DESC").paginate(page: page, per_page: per_page)
    end
  end

  def get_transpoter_iou_list(user, page, per_page)
    Iou.where("transporter_id = ? and is_received = ? and (DATE(updated_at) > ? and DATE(updated_at) <= ?)", user.id, false, Date.today - 3, Date.today).distinct.paginate(page: page, per_page: per_page)
  end
end
