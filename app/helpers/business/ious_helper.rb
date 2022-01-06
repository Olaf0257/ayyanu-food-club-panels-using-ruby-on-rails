module Business::IousHelper
  def get_branch_wise_iou(branches, branch_id, keyword)
    all_transporter = []

    branches.each do |branch|
      transporter = branch.branch_transports.pluck(:user_id)
      all_transporter += transporter
    end

    if branch_id.present? && keyword.present?
      branch = get_branch(branch_id)
      transporters = branch.branch_transports
      ious = Iou.includes(:order, :transporter).joins(:transporter).where("(ious.transporter_id IN (?) and order_id = ? or cpr_number = ?)", transporters.pluck(:user_id), keyword, keyword)
    elsif branch_id.present?
      branch = get_branch(branch_id)
      transporters = branch.branch_transports
      ious = Iou.includes(:user, :order, :transporter).joins(:user).where("ious.transporter_id IN (?)", transporters.pluck(:user_id))
    elsif keyword.present?
      ious = Iou.includes(:order, :transporter).joins(:transporter).where("ious.order_id = (?) or cpr_number = ?", keyword.to_s, keyword.to_s)
    else
      ious = Iou.includes(:user, :order, :transporter).where(transporter_id: all_transporter)
    end

    ious.order_by_date_desc
  end
end
