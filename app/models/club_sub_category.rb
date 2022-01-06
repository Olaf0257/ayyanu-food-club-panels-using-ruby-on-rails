class ClubSubCategory < ApplicationRecord
  belongs_to :club_category
  has_many :user_clubs, dependent: :destroy
  has_many :users, through: :user_clubs

  def as_json(options = {})
    @logdinUser = options[:logdinUser]
    @language = options[:language]
    super(options.merge(except: [:created_at, :updated_at, :club_category_id, :title_ar, :title], methods: [:status, :title]))
  end

  def self.find_sub_category(sub_category_id)
    find(sub_category_id)
  end

  def status
    userclube = UserClub.find_by(user_id: @logdinUser, club_sub_category_id: id)
    if userclube
      true
    else
      false
    end
  end

  def self.add_new_sub_category(club_id, club_sub_title, club_sub_title_ar)
    create(title: club_sub_title, club_category_id: club_id, title_ar: club_sub_title_ar)
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

  def self.sub_category_list_csv
    CSV.generate do |csv|
      header = "Sub Club List for #{all.first&.club_category&.title}"
      csv << [header]

      second_row = ["ID", "Sub Club Name (English)", "Sub Club Name (Arabic)"]
      csv << second_row

      all.each do |club|
        @row = []
        @row << club.id
        @row << (club.title.presence || "NA")
        @row << (club.title_ar.presence || "NA")
        csv << @row
      end
    end
  end
end
