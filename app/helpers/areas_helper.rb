module AreasHelper
  def add_new_coverage_area(coverage_area, coverage_area_ar, city, country, location, latitude, longitude)
    #city = City.create(city: city, country: country)
    city = City.create(city: city)
    CoverageArea.create(area: coverage_area, area_ar: coverage_area_ar, city_id: city.id, country_id: country, location: location, latitude: latitude, longitude: longitude)
  end

  def get_coverage_area_with_id(id)
    CoverageArea.find_by(id: id)
  end

  def get_coverage_area_list
    CoverageArea.all
  end

  def get_branch_coverage_area_list(branch)
    area = []
    area_list = get_coverage_area_list.where(country_id: branch.restaurant.country_id)

    area_list.each do |ar|
      branch_area = branch.branch_coverage_areas.find_by(coverage_area_id: ar.id)

      if branch_area.present?
        area << { id: ar.id, area: ar.area, delivery_charges: branch_area.delivery_charges, minimum_amount: branch_area.minimum_amount, delivery_time: branch_area.delivery_time, third_party_delivery: to_boolean(branch_area.third_party_delivery), third_party_delivery_type: branch_area.third_party_delivery_type, cash_on_delivery: to_boolean(branch_area.cash_on_delivery), accept_cash: to_boolean(branch_area.accept_cash), accept_card: to_boolean(branch_area.accept_card), is_closed: to_boolean(branch_area.is_closed), is_busy: to_boolean(branch_area.is_busy), far_menu: to_boolean(branch_area.far_menu) }
      else
        area << { id: ar.id, area: ar.area, delivery_charges: "0.5", minimum_amount: "2", delivery_time: "60", third_party_delivery: to_boolean(false), third_party_delivery_type: "Chargeable", cash_on_delivery: to_boolean(true), accept_cash: to_boolean(true), accept_card: to_boolean(true), is_closed: to_boolean(true), is_busy: to_boolean(true), far_menu: to_boolean(true) }
      end
    end

    area
  end
end
