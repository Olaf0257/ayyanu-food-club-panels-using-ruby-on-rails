require "#{Rails.root}/app/helpers/enterprises_helper"
include EnterprisesHelper

namespace :migrate_restaurant do
  desc "Migrate Restaurant to enterprise"
  task migrate_restaurant_to_enterprise: :environment do
    Restaurant.all.each do |restaurant|
      new_restaurant = NewRestaurant.find_by_restaurant_name(restaurant.title)
      unless new_restaurant.blank?
        enterprise = add_enterprise_request(new_restaurant.mother_company_name, nil, new_restaurant.person_name, new_restaurant.contact_number, new_restaurant.role, new_restaurant.email, new_restaurant.coverage_area_id, new_restaurant.cuisine, new_restaurant.cr_number, new_restaurant.bank_name, new_restaurant.bank_account, nil, nil, new_restaurant.cpr_number, new_restaurant.owner_name, new_restaurant.nationality, new_restaurant.submitted_by, new_restaurant.delivery_status, new_restaurant.branch_no, new_restaurant.mother_company_name, new_restaurant.serving, new_restaurant.block, new_restaurant.road_number, new_restaurant.building, new_restaurant.unit_number, new_restaurant.floor, new_restaurant.other_user_name, new_restaurant.other_user_role, new_restaurant.other_user_email, new_restaurant.country_id)
        enterprise.update(is_approved: true, user_id: restaurant.user_id)
      end
    end
  end
end
