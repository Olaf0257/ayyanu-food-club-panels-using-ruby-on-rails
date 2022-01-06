class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :branch
  belongs_to :order, optional: true

  after_commit :set_branch_avg_rating

  scope :active, -> { where(driver_hidden: false) }

  def as_json(options = {})
    super(options.merge(except: [:updated_at, :user_id, :branch_id, :review_title], methods: [:food_quality_rating]))
  end

  def self.create_rating(user, rating, description, order_id, branch_id, food_quantity_rating, food_taste_rating, value_rating, packaging_rating, seal_rating, delivery_time_rating, clean_uniform_rating, polite_rating, distance_rating, mask_rating, driver_rating, driver_comments)
    rating = create(user_id: user.id, order_id: order_id, branch_id: branch_id, review_description: description, rating: rating, food_quantity_rating: food_quantity_rating, food_taste_rating: food_taste_rating, value_rating: value_rating, packaging_rating: packaging_rating, seal_rating: seal_rating, delivery_time_rating: delivery_time_rating, clean_uniform_rating: clean_uniform_rating, polite_rating: polite_rating, distance_rating: distance_rating, mask_rating: mask_rating, driver_rating: driver_rating, driver_comments: driver_comments)
    rating ? { code: 200, result: rating } : { code: 400, result: rating.errors.full_messages.join(", ") }
  end

  def food_quality_rating
    ""
  end

  def self.get_order_rating(order_id)
    find_by(order_id: order_id)
  end

  def self.restaurant_rating_csv(restaurant_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Restaurant Ratings List"
      csv << [header]
      csv << ["Restaurant: " + restaurant_name, "Start Date: " + start_date.presence || "NA", "End Date: " + end_date.presence || "NA"]

      second_row = ["Order Id", "Branch", "User", "Review", "Quantity of Food Rating", "Food Taste Rating", "Value for Money Rating", "Order Packaging Rating", "Order Seal Rating", "Overall Rating", "Time"]
      csv << second_row

      all.order("created_at DESC").each do |rating|
        @row = []
        @row << rating.order_id
        @row << (rating.branch.address.presence || "N/A")
        @row << (rating.user.present? ? rating.user.name.presence || "N/A" : "N/A")
        @row << (rating.review_description.presence || "N/A")
        @row << (rating.food_quantity_rating.presence || "NA")
        @row << (rating.food_taste_rating.presence || "NA")
        @row << (rating.value_rating.presence || "NA")
        @row << (rating.packaging_rating.presence || "NA")
        @row << (rating.seal_rating.presence || "NA")
        @row << (rating.rating.presence || "NA")
        @row << rating.created_at.strftime("%d %b %Y %l:%M:%S %p")
        csv << @row
      end
    end
  end

  def self.admin_driver_rating_csv(company_id, restaurant_id, start_date, end_date)
    restaurant_name = restaurant_id.present? ? Restaurant.find(restaurant_id).title : "All"
    company_name = company_id.present? ? DeliveryCompany.find(company_id).name : "All"

    CSV.generate do |csv|
      header = "Driver Reviews"
      csv << [header]
      csv << ["Restaurant: " + restaurant_name, "Delivery Company: " + company_name, "Start Date: " + (start_date.presence || "NA"), "End Date: " + (end_date.presence || "NA")]

      second_row = ["Order Id", "Restaurant", "Branch", "User", "Driver", "Delivery Company", "Review", "Delivery Time", "Clean Uniform", "Polite", "Keeping Distance", "Wearing Mask", "Overall Rating" ,"Time"]
      csv << second_row

      all.each do |rating|
        @row = []
        @row << rating.order_id
        @row << rating.branch.restaurant.title
        @row << (rating.branch.address.presence || "N/A")
        @row << (rating.user.present? ? rating.user.name.presence || "N/A" : "N/A")
        @row << (rating.order.transporter&.name || "NA")
        @row << (rating.order.transporter&.delivery_company&.name || "NA")
        @row << (rating.driver_comments.present? ? rating.driver_comments : "N/A")
        @row << (rating.delivery_time_rating.presence || "NA")
        @row << (rating.clean_uniform_rating.presence || "NA")
        @row << (rating.polite_rating.presence || "NA")
        @row << (rating.distance_rating.presence || "NA")
        @row << (rating.mask_rating.presence || "NA")
        @row << (rating.driver_rating.presence || "NA")
        @row << rating.created_at.strftime("%d %b %Y %l:%M:%S %p")
        csv << @row
      end

      csv << ["Average Delivery Time Rating", all.average(:delivery_time_rating).to_f.round(1)]
      csv << ["Average Clean Uniform Rating", all.average(:clean_uniform_rating).to_f.round(1)]
      csv << ["Average Polite Rating", all.average(:polite_rating).to_f.round(1)]
      csv << ["Average Keeping Distance Rating", all.average(:distance_rating).to_f.round(1)]
      csv << ["Average Wearing Mask Rating", all.average(:mask_rating).to_f.round(1)]
      csv << ["Average Overall Rating", all.average(:driver_rating).to_f.round(1)]
    end
  end

  def self.delivery_company_driver_rating_csv(restaurant_id, company, start_date, end_date)
    restaurant_name = restaurant_id.present? ? Restaurant.find(restaurant_id).title : "All"

    CSV.generate do |csv|
      header = company.name + " Driver Reviews"
      csv << [header]
      csv << ["Restaurant: " + restaurant_name, "Start Date: " + (start_date.presence || "NA"), "End Date: " + (end_date.presence || "NA")]

      second_row = ["Order Id", "Restaurant", "Branch", "Driver", "Review", "Delivery Time", "Clean Uniform", "Polite", "Keeping Distance", "Wearing Mask", "Overall Rating" ,"Time"]
      csv << second_row

      all.each do |rating|
        @row = []
        @row << rating.order_id
        @row << rating.branch.restaurant.title
        @row << (rating.branch.address.presence || "N/A")
        @row << (rating.order.transporter&.name || "NA")
        @row << (rating.driver_comments.present? ? rating.driver_comments : "N/A")
        @row << (rating.delivery_time_rating.presence || "NA")
        @row << (rating.clean_uniform_rating.presence || "NA")
        @row << (rating.polite_rating.presence || "NA")
        @row << (rating.distance_rating.presence || "NA")
        @row << (rating.mask_rating.presence || "NA")
        @row << (rating.driver_rating.presence || "NA")
        @row << rating.created_at.strftime("%d %b %Y %l:%M:%S %p")
        csv << @row
      end

      csv << ["Average Delivery Time Rating", all.average(:delivery_time_rating).to_f.round(1)]
      csv << ["Average Clean Uniform Rating", all.average(:clean_uniform_rating).to_f.round(1)]
      csv << ["Average Polite Rating", all.average(:polite_rating).to_f.round(1)]
      csv << ["Average Keeping Distance Rating", all.average(:distance_rating).to_f.round(1)]
      csv << ["Average Wearing Mask Rating", all.average(:mask_rating).to_f.round(1)]
      csv << ["Average Overall Rating", all.average(:driver_rating).to_f.round(1)]
    end
  end

  private

  def set_branch_avg_rating
    branch.update(avg_rating: Rating.where(branch_id: branch_id).where.not(rating: ["", nil]).average(:rating).to_f.round(1))
  end
end
