class Subscription < ApplicationRecord
  belongs_to :restaurant, optional: true
  belongs_to :branch, optional: true

  def self.add_subscribe_report(restaurant, branch)
    service_fee = Servicefee.last
    if restaurant.present?
      create(restaurant_id: restaurant.id, subscribe_date: DateTime.now, report_expaired_at: DateTime.now + 1.month, is_subscribe: true, subscribe_for: "report", plan_price: service_fee.report_subscribe_fee)
      restaurant.update(is_subscribe: true)
    else
      create(branch_id: branch.id, subscribe_date: DateTime.now, report_expaired_at: DateTime.now + 1.month, is_subscribe: true, subscribe_for: "branch", plan_price: service_fee.branch_subscription_fee)
     end
  end

  def self.filter_subscription(keyword, sortKey, sortBy, page, per_page, admin)
    if admin.class.name =='SuperAdmin'
      if keyword.present?
        joins(:restaurant).where("restaurant_id IS NOT NULL and restaurants.title like (?)", "%#{keyword}%").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
      else
        where("restaurant_id IS NOT NULL").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
      end
      else
        country_id = admin.class.find(admin.id)[:country_id]
        if keyword.present?
          includes(:restaurant).where(restaurants: { country_id: country_id }).joins(:restaurant).where("restaurant_id IS NOT NULL and restaurants.title like (?)", "%#{keyword}%").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
        else
          includes(:restaurant).where(restaurants: { country_id: country_id }).where("restaurant_id IS NOT NULL").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
        end
      end
  end

  def self.filter_branch_subscription(keyword, sortKey, sortBy, page, per_page, admin)
    if admin.class.name =='SuperAdmin'
      if keyword.present?
        joins(:branch).where("branch_id IS NOT NULL and branches.address like (?)", "%#{keyword}%").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
      else
        where("branch_id IS NOT NULL").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
      end
    else
      country_id = admin.class.find(admin.id)[:country_id]
      if keyword.present?
        includes(:restaurant).where(restaurants: { country_id: country_id }).joins(:branch).where("branch_id IS NOT NULL and branches.address like (?)", "%#{keyword}%").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
      else
        includes(:restaurant).where(restaurants: { country_id: country_id }).where("branch_id IS NOT NULL").order("#{sortKey} #{sortBy}").paginate(page: page, per_page: per_page)
      end
    end
  end
end
