class RestaurantDocument < ApplicationRecord
  belongs_to :restaurant

  def self.find_restaurant_doc(page, per_page, id, admin)
    if admin.class.name =='SuperAdmin'
      if id.present?
        where(restaurant_id: id).paginate(page: page, per_page: per_page)
      else
        paginate(page: page, per_page: per_page)
      end
    else
      country_id = admin.class.find(admin.id)[:country_id]
      if id.present?
        includes(:restaurant).where(restaurants: { country_id: country_id }).where(restaurant_id: id).paginate(page: page, per_page: per_page)
      else
        includes(:restaurant).where(restaurants: { country_id: country_id }).paginate(page: page, per_page: per_page)
      end

    end
  end
end
