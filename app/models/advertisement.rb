class Advertisement < ApplicationRecord
  include Imagescaler
  belongs_to :restaurant
  belongs_to :branch
  belongs_to :add_request

  def as_json(options = {})
    @imgWidth = options[:imgWidth]
    super(options.merge(except: [:created_at, :updated_at, :restaurant_id, :transaction_id], methods: [:image_thumb]))
  end

  def self.find_advertisement(page, _per_page)
    advertisements = Advertisement.paginate(page: page, per_page: 3)
  end

  def image_thumb
    # img_thumb(self.image, @imgWidth)
    image
  end

  def self.get_branchId(branch_id)
    where(branch_id: branch_id)
  end

  def self.get_business_offer(offer_id, restaurant_id)
    find_by(id: offer_id, restaurant_id: restaurant_id)
  end

  def self.create_advertisement(restaurant_id, place, position, title, description, amount, from_date, to_date, add_request_id, branch_id, image)
    create!(restaurant_id: restaurant_id, place: place, position: position, title: title, description: description, amount: amount, from_date: from_date, to_date: to_date, add_request_id: add_request_id, branch_id: branch_id, image: image)
  end

  # def self.find_restaurant_advertisement user
  #   p "================"
  #   p user
  #   where(:restaurant_id=>user.restaurant.id)
  # end

  def self.find_all_advertisement_list(admin)
    if admin.class.name =='SuperAdmin'
      where("from_date != ? and to_date !=? ", "nil", "nil").order("id Desc")
    else
      country_id = admin.class.find(admin.id)[:country_id]
      includes(:restaurant).where(restaurants: { country_id: country_id }).where("from_date != ? and to_date !=? ", "nil", "nil").order("advertisements.id Desc")
    end
  end

  # methods after update
  def self.find_restaurant_advertisement(restaurant)
    p "================"
    p restaurant
    where(restaurant_id: restaurant)
  end

  def self.admin_advertisement_list_csv
    CSV.generate do |csv|
      header = "Advertisment List"
      csv << [header]

      second_row = ["Id", "Title", "Restaurant Name", "Branch Address", "Place", "Position", "Amount", "Created On", "Status"]
      csv << second_row

      all.order("created_at DESC").each do |advertisment|
        currency = advertisment.branch.currency_code_en
        @row = []
        @row << advertisment.id
        @row << advertisment.title
        @row << advertisment.restaurant.title
        @row << branch_address = advertisment.branch.present? ? advertisment.branch.address.present? ? advertisment.branch.address : "" : ""
        @row << advertisment.place
        @row << advertisment.position
        @row << format("%0.03f", advertisment.amount) + " " + currency
        @row << advertisment.created_at.strftime("%d/%m/%Y")
        @row << status = (advertisment.to_date > Date.today and advertisment.from_date <= Date.today) ? "Running" : (advertisment.from_date > Date.today) ? "Upcoming" : "Closing"
        csv << @row
      end
    end
  end

  def self.business_advertisement_list_csv
    CSV.generate do |csv|
      header = "Advertisment List"
      currency = all.first&.branch&.currency_code_en.to_s
      csv << [header]

      second_row = ["Id", "Title", "Restaurant Name", "Branch Address", "Place", "Position", "Amount (#{currency})", "Status"]
      csv << second_row

      all.order("created_at DESC").each do |advertisment|
        @row = []
        @row << advertisment.id
        @row << advertisment.title
        @row << advertisment.restaurant.title
        @row << advertisment.branch&.address
        @row << advertisment.place
        @row << advertisment.position
        @row << format("%0.03f", advertisment.amount)
        @row << status = (advertisment.to_date > Date.today and advertisment.from_date <= Date.today) ? "Running" : (advertisment.from_date > Date.today) ? "Upcoming" : "Closed"
        csv << @row
      end
    end
  end
end
