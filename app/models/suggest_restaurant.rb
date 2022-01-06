class SuggestRestaurant < ApplicationRecord
  belongs_to :restaurant
  belongs_to :coverage_area
  belongs_to :user, optional: true
  before_save :downcase_suggest_restaurant_stuff

  def as_json(options = {})
    super(options.merge(except: [:updated_at, :created_at]))
  end

  def self.create_suggest_restaurant(branch, description, area_id, user_id)
    suggest = create(description: description, restaurant_id: branch.restaurant.id, coverage_area_id: area_id, user_id: user_id)
  end

  def self.suggested_list_csv
    CSV.generate do |csv|
      header = "Suggested Restaurants List"
      csv << [header]

      second_row = ["Restaurant", "Area", "Country", "Suggestion Count"]
      csv << second_row

      all.group_by { |s| [s.restaurant, s.coverage_area] }.sort_by { |s| s.last.size }.reverse.each do |k, v|
        @row = []
        @row << k.first.title
        @row << k.last.area
        @row << k.first.country&.name
        @row << v.size
        csv << @row
      end
    end
  end

  private

  def downcase_suggest_restaurant_stuff
    self.description = description.capitalize
  end
end
