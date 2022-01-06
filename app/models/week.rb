class Week < ApplicationRecord
  has_many :add_requests, dependent: :destroy
  belongs_to :country, optional: true
  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at]))
 end

  def self.get_week(week_id)
    find_by(id: week_id)
  end

  def self.create_week(start_date, end_date, title, country)
    check_date = find_by(start_date: start_date, end_date: end_date, country_id: country)
    Week.create(start_date: start_date.to_date, end_date: end_date.to_date, title: title, country_id: country) unless check_date
  end
  # def find_week_data
  # .paginate(:page=>params[:page],:per_page=>params[:per_page])
  # end
end
