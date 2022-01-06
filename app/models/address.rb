class Address < ApplicationRecord
  belongs_to :user
  belongs_to :coverage_area
  has_many :pos_checks, dependent: :destroy

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :user_id]))
  end

  def self.find_address(address_id)
    find_by(id: address_id)
  end

  def area_name
    area.presence || coverage_area&.area
  end

  def self.create_address(user, guestToken, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude, area_id)
    userAddress = Address.create(address_type: address_type, address_name: address_name, fname: fname, lname: lname, area: area, block: block, street: street, building: building, floor: floor, apartment_number: apartment_number, additional_direction: additional_direction, country_code: country_code, contact: contact, landline: landline, user_id: user.id, latitude: latitude, longitude: longitude, coverage_area_id: area_id, guest_token: guestToken)
    userAddress ? { code: 200, result: userAddress } : { code: 400, result: userAddress.errors.full_messages.join(", ") }
  end

  def self.edit_address(address, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude)
    updateAddress = address.update(address_type: address_type, address_name: address_name, fname: fname, lname: lname, area: area, block: block, street: street, building: building, floor: floor, apartment_number: apartment_number, additional_direction: additional_direction, country_code: country_code, contact: contact, landline: landline, latitude: latitude, longitude: longitude, contact_verification: address.contact == contact ? address.contact_verification : false)
    updateAddress ? { code: 200, result: updateAddress } : { code: 400, result: updateAddress.errors.full_messages.join(", ") }
  end

  def self.find_area_address_wise(user, area_id, page, per_page)
    if area_id.present?
      where("coverage_area_id = (?) and user_id = (?)", area_id, user.id).paginate(page: page, per_page: per_page)
    else
      user.addresses.paginate(page: page, per_page: per_page)
    end
  end

  def self.find_guest_user_address(guestToken)
    find_by(guest_token: guestToken)
  end

  def self.user_address_list_csv(user_name)
    CSV.generate do |csv|
      header = "#{user_name} Addresses List"
      csv << [header]

      second_row = ["Country", "Area", "Address Name", "Address Type", "Block", "Road No", "Building", "Floor", "Villa/Apartment/Office No", "Additional Directions", "Contact", "Landline"]
      csv << second_row

      all.sort_by(&:area_name).each do |address|
        @row = []
        @row << address.coverage_area&.country&.name
        @row << address.area_name
        @row << address.address_name
        @row << address.address_type
        @row << address.block
        @row << address.street
        @row << address.building
        @row << address.floor
        @row << address.apartment_number
        @row << address.additional_direction
        @row << address.contact
        @row << address.landline
        csv << @row
      end
    end
  end
end
