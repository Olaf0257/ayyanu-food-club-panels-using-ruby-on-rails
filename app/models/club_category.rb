class ClubCategory < ApplicationRecord
  has_many :club_sub_categories, dependent: :destroy
  def as_json(options = {})
    @language = options[:language]
    super(options.merge(except: [:created_at, :updated_at, :title, :description, :title_ar, :description_ar], methods: [:title, :description]))
  end

  def self.find_all_club_category(page, per_page)
    paginate(page: page, per_page: per_page)
  end

  def self.find_category(category_id)
    find(category_id)
  end

  def self.add_club_data(title, club_description, image, club_title_ar, club_description_ar)
    create(title: title, img_url: image, description: club_description, title_ar: club_title_ar, description_ar: club_description_ar)
  end

  def title
    if @language == "english"
      self["title"]
    elsif @language == "arabic"
      self["title_ar"].presence || self["title"]
    else
      self["title"]
    end
  end

  def description
    if @language == "english"
      self["description"]
    elsif @language == "arabic"
      self["description_ar"].presence || self["description"]
    else
      self["description"]
    end
  end

  def self.club_list_csv
    CSV.generate do |csv|
      header = "Club List"
      csv << [header]

      second_row = ["ID", "Club Name (English)", "Club Name (Arabic)", "Club Description (English)", "Club Description (Arabic)", "Club Sub Categories"]
      csv << second_row

      all.each do |club|
        @row = []
        @row << club.id
        @row << (club.title.presence || "NA")
        @row << (club.title_ar.presence || "NA")
        @row << (club.description.presence || "NA")
        @row << (club.description_ar.presence || "NA")
        @row << club.reload.club_sub_categories.map(&:title).join(", ")
        csv << @row
      end
    end
  end
end
