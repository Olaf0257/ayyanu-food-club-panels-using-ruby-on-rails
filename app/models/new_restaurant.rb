class NewRestaurant < ApplicationRecord
  require "dropbox"
  belongs_to :country, optional: true
  belongs_to :coverage_area
  belongs_to :restaurant, optional: true
  has_many :new_restaurant_images, dependent: :destroy
  before_save :downcase_restaurant_stuff

  scope :requested_list, -> { where(is_rejected: false, is_approved: false) }
  scope :rejected_list, -> { where(is_rejected: true) }

  def self.create_restaurant_request_details(restaurant_name, restaurant_id, person_name, contact_number, role, email, area, cuisine, cr_number, bank_name, bank_account, cpr_number, owner_name, nationality, submitted_by, delivery_status, branch_no, mother_company_name, serving, block, road_number, building, unit_number, floor, other_name, other_role, other_email,country_id)
    data = create(restaurant_name: restaurant_name, restaurant_id: restaurant_id != "undefined" ? restaurant_id : "", person_name: person_name, contact_number: contact_number, role: role, email: email, coverage_area_id: area, cuisine: cuisine, cr_number: cr_number, bank_name: bank_name, bank_account: bank_account, cpr_number: cpr_number, owner_name: owner_name, nationality: nationality, submitted_by: submitted_by, delivery_status: delivery_status, branch_no: branch_no, mother_company_name: mother_company_name, serving: serving, road_number: road_number, building: building, unit_number: unit_number, floor: floor, other_user_email: role == "other" ? other_email : "", other_user_name: role == "other" ? other_name : "", other_user_role: role == "other" ? other_role : "", block: block, country_id: country_id)
  end

  def self.find_new_restaurant(restaurant_id)
    find_by(id: restaurant_id)
  end

  def self.search_by_name_and_country(keyword, country_id)
    result = if country_id.present? && keyword.present?
               where(country_id: country_id).where("restaurant_name LIKE ?", "%#{keyword}%")
             elsif country_id.present?
               where(country_id: country_id)
             elsif keyword.present?
               where("restaurant_name LIKE ?", "%#{keyword}%")
             else
               all
             end

    result
  end

  def self.requested_restaurant_list_csv
    CSV.generate do |csv|
      header = "Requested Restaurant List"
      csv << [header]

      second_row = ["ID", "Restaurant Name", "Owner Name", "Contact Number", "Email", "Area", "Submitted By", "Country", "Requested On"]
      csv << second_row

      all.each do |restaurant|
        @row = []
        @row << restaurant.id
        @row << restaurant.restaurant_name
        @row << restaurant.owner_name
        @row << restaurant.contact_number
        @row << restaurant.email
        @row << restaurant.coverage_area.area
        @row << (restaurant.person_name.presence || "N/A")
        @row << restaurant.country&.name
        @row << restaurant.created_at.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  def self.rejected_restaurant_list_csv
    CSV.generate do |csv|
      header = "Rejected Restaurant List"
      csv << [header]

      second_row = ["ID", "Restaurant Name", "Person Name", "Contact Number", "Email", "Area", "Submitted By", "Country", "Rejected On"]
      csv << second_row

      all.each do |restaurant|
        @row = []
        @row << restaurant.id
        @row << restaurant.restaurant_name
        @row << restaurant.owner_name
        @row << restaurant.contact_number
        @row << restaurant.email
        @row << restaurant.coverage_area.area
        @row << (restaurant.submitted_by.presence || "N/A")
        @row << restaurant.country&.name
        @row << restaurant.rejected_at&.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  private

  def downcase_restaurant_stuff
    self.restaurant_name = restaurant_name.capitalize
    self.person_name = person_name.capitalize
    self.email = email.downcase
    self.owner_name = owner_name.capitalize
    self.submitted_by = submitted_by.capitalize
    self.mother_company_name = mother_company_name&.capitalize
    self.other_user_email = other_user_email&.downcase
    self.other_user_name = other_user_name&.capitalize
    self.country_id = 15 if country_id.nil?
  end
end
