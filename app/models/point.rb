class Point < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true
  belongs_to :branch

  scope :credited, -> { where(point_type: "Credit") }
  scope :debited, -> { where(point_type: "Debit") }

  def as_json(options = {})
    super(options.merge(except: [:updated_at, :user_id, :branch_id, :order_id]))
  end

  def self.create_point(order, user, point, point_type)
    point = create(user_id: user, order_id: order.id, branch_id: order.branch_id, user_point: point, point_type: point_type)
    point ? { code: 200, result: point } : { code: 400, result: point.errors.full_messages.join(", ") }
  end

  def self.find_user_point(user, _page, _per_page, language)
    ious = []
    totalPoint = 0
    branchs = where("user_id = ? ", user.id).order(id: "DESC").pluck(:branch_id).uniq
    currency_code = Branch.find_by(id: branchs.first)&.restaurant&.country&.currency_code.to_s
    branchs.each do |id|
      point = where("user_id = ? and branch_id = (?)", user.id, id).pluck(:user_point).sum
      redeemPoint = Point.where("user_id = ? and branch_id = (?) and point_type = ? ", user.id, id, "Debit")
      point = Point.where("user_id = ? and branch_id = (?) and point_type = (?)", user.id, id, "Credit")
      # # point = redeemPoint.present? ? redeemPoint.last.remaining_point : where("user_id = ? and branch_id = (?)",user.id,id)
      branch = redeemPoint.present? ? Branch.find(redeemPoint.last.branch_id) : point.first.branch
      # # userPoint = redeemPoint.present? ? point : point.pluck(:user_point).sum
      userPoint = point.pluck(:user_point).sum - redeemPoint.pluck(:user_point).sum
      user_point = {}
      totalPoint += userPoint
      user_point["user_point"] = userPoint
      branch.language = language
      user_point["branch"] = branch.as_json(language: language, only: [:id, :address], methods: [:restaurant_name, :restaurant_logo])
      ious << user_point
    end
    { point: ious, totalPoint: totalPoint, currency_code_en: currency_code, currency_code_ar: currency_code }
  end

  def self.find_user_point_list(user, _page, _per_page)
    where("user_id = ? ", user.id).order(id: "DESC")
  end

  def self.find_branch_wise_point(branch_id, user, page, per_page)
    where("user_id = ? and branch_id = ? ", user.id, branch_id).order(id: "DESC").paginate(page: page, per_page: per_page)
  end

  def self.influencer_selling_points(user_id, restaurant_id)
    joins(:branch).where(user_id: user_id, branches: { restaurant_id: restaurant_id }).order(id: :desc)
  end

  def self.sellable_restaurant_wise_points(country_id)
    user_ids = joins(:user).where(users: { country_id: country_id, influencer: true }).pluck(:user_id).uniq
    result = []

    user_ids.each do |user_id|
      point_data = where(user_id: user_id).joins(:branch)
      restaurant_ids = point_data.pluck("branches.restaurant_id").uniq

      restaurant_ids.each do |restaurant_id|
        sum = (point_data.credited.where(branches: { restaurant_id: restaurant_id }).sum(:user_point) - point_data.debited.where(branches: { restaurant_id: restaurant_id }).sum(:user_point)).to_f.round(3)
        result += [[user_id, restaurant_id]] if sum >= 50
      end
    end

    result
  end
end
