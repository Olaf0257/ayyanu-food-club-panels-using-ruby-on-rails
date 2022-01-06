module Api::V1::AddressHelper
  def address_json(address)
    address.as_json(include: [coverage_area: { only: [:id, :area] }])
  end

  def get_user_address(address_id)
    Address.find_address(address_id)
  end

  def update_user_address(address, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude)
    Address.edit_address(address, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude)
  end

  def get_address_area_wise(user, area_id, page, per_page)
    Address.find_area_address_wise(user, area_id, page, per_page)
  end

  def get_guest_user_address(guestToken)
    Address.find_guest_user_address(guestToken)
  end
end
