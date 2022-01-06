class AddRequest < ApplicationRecord
  belongs_to :branch
  belongs_to :coverage_area
  belongs_to :week
  has_one :advertisement, dependent: :destroy

  after_save :inform_ad_requester

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :branch_id, :coverage_area_id, :week_id, :transaction_id], methods: [:currency_code_en, :currency_code_ar]))
  end

  def currency_code_en
    branch.restaurant.country.currency_code.to_s
  end

  def currency_code_ar
    branch.restaurant.country.currency_code.to_s
  end

  def inform_ad_requester
    AddRequestNotificationWorker.perform_at(1.hour.from_now, id) if place == "list"
  end

  def self.get_adds_req(adds_id)
    find_by(id: adds_id)
  end

  def self.create_adds_request(position, place, title, description, amount, week_id, branch_id, coverage_area_id, url)
    adds = new(position: position, place: place, title: title, description: description, amount: amount, week_id: week_id, branch_id: branch_id, coverage_area_id: coverage_area_id, image: url)
    adds.save!
    !adds.id.nil? ? { code: 200, result: adds } : { code: 400, result: adds.errors.full_messages.join(", ") }
    adds
  end

  def self.get_week_offers(date1, date2)
    where("Date(created_at) >= ? or Date(created_at) <= ?", date1, date2)
  end

  def self.get_place_offers(position, admin)
    # where("position = ?", position).order("id DESC")

    if admin.class.name == "SuperAdmin"
      where("position = ?", position).order("id DESC")
    else
      country_id = admin.class.find(admin.id)[:country_id]
      includes(branch: :restaurant).where(restaurants: { country_id: country_id }).where("position = ?", position).order("add_requests.id DESC")
    end
  end

  def self.find_all_reject_list(admin)
    if admin.class.name =='SuperAdmin'
      where("is_reject = ?", true)
    else
      country_id = admin.class.find(admin.id)[:country_id]
      includes(branch: :restaurant).where(restaurants: { country_id: country_id }).where("is_reject = ?", true)
    end
  end

  def self.find_all_ads(_user, restaurant)
    where("branch_id IN (?) and is_accepted = ?", restaurant.branches.pluck(:id), false).order("id DESC")
  end

  def self.rejected_advertisement_list_csv
    CSV.generate do |csv|
      header = "Rejected Advertisment List"
      csv << [header]

      second_row = ["ID", "Place Type", "Position", "Title", "Restaurant", "Branch", "Start Date", "End Date", "Amount", "Created On", "Status"]
      csv << second_row

      all.order("created_at DESC").each do |advertisment|
        currency = advertisment.branch.currency_code_en
        @row = []
        @row << advertisment.id
        @row << advertisment.place
        @row << advertisment.position
        @row << advertisment.title
        @row << advertisment.branch.restaurant.title
        @row << advertisment.branch.address
        @row << advertisment.week.start_date.strftime("%A, %d %B %Y")
        @row << advertisment.week.end_date.strftime("%A, %d %B %Y")
        @row << format("%0.03f", advertisment.amount) + " " + currency
        @row << advertisment.created_at.strftime("%d/%m/%Y")
        @row << status = advertisment.is_reject ? "Reject" : "Pending"
        csv << @row
      end
    end
  end

  def self.offers_list_csv
    CSV.generate do |csv|
      header = "Offers List"
      csv << [header]

      second_row = ["ID", "Place Type", "Position", "Title", "Restaurant", "Branch", "Start Date", "End Date", "Amount", "Requested On", "Status"]
      csv << second_row

      all.order("created_at DESC").each do |advertisment|
        currency = advertisment.branch.currency_code_en
        @row = []
        @row << advertisment.id
        @row << advertisment.place
        @row << advertisment.position
        @row << advertisment.title
        @row << advertisment.branch.restaurant.title
        @row << advertisment.branch.address
        @row << advertisment.week.start_date.strftime("%A, %d %B %Y")
        @row << advertisment.week.end_date.strftime("%A, %d %B %Y")
        @row << format("%0.03f", advertisment.amount) + " " + currency
        @row << advertisment.created_at.strftime("%d/%m/%Y")
        @row << status = advertisment.is_accepted ? "Approved" : advertisment.is_reject ? "Rejected" : "Pending"
        csv << @row
      end
    end
  end

  def self.pending_advertisement_list_csv
    CSV.generate do |csv|
      header = "Pending Advertisment List"
      currency = all.first&.branch&.currency_code_en
      csv << [header]

      second_row = ["ID", "Place Type", "Position", "Title", "Branch", "Area", "Start Date", "End Date", "Amount (#{currency})", "Status"]
      csv << second_row

      all.order("created_at DESC").each do |advertisment|
        @row = []
        @row << advertisment.id
        @row << advertisment.place
        @row << advertisment.position
        @row << advertisment.title
        @row << advertisment.branch.address
        @row << advertisment.coverage_area.area
        @row << advertisment.week.start_date.strftime("%A, %d %B %Y")
        @row << advertisment.week.end_date.strftime("%A, %d %B %Y")
        @row << format("%0.03f", advertisment.amount)
        @row << status = advertisment.is_reject ? "Reject" : "Not Accepted"
        csv << @row
      end
    end
  end
end
