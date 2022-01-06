module ClubesHelper
  def find_sub_category(title)
    ClubSubCategory.find_by(title: title)
  end

  def get_club_details(id)
    ClubCategory.find_by(id: id)
  end

  def find_club_sub_category(id)
    ClubSubCategory.find_by(id: id)
  end

  def get_club(club_title)
    ClubCategory.find_by(title: club_title)
  end

  def club_sub_category_add(club_id, club_sub_title, club_sub_title_ar)
    ClubSubCategory.add_new_sub_category(club_id, club_sub_title, club_sub_title_ar)
  end

  def add_new_club(club_title, club_description, club_image, club_title_ar, club_description_ar)
    image = upload_multipart_image(params[:club_image], "club_image") if club_image.present?
    ClubCategory.add_club_data(club_title, club_description, image, club_title_ar, club_description_ar)
  end

  def get_club_users(club_id, page, per_page, category, keyword, start_date, end_date)
    if ClubCategory.all.map(&:title).include?(category.title)
      users = User.joins(club_sub_categories: :club_category).where("club_category_id = ?", club_id)
    else
      users = User.joins(:club_sub_categories).where("club_sub_categories.id = ?", club_id)
    end

    users = users.where("users.name like ?", "%#{keyword}%") if keyword.present?
    users = users.joins(:user_clubs).where(user_clubs: { club_sub_category_id: club_id }).where("DATE(user_clubs.created_at) >= ?", start_date.to_date) if start_date.present?
    users = users.joins(:user_clubs).where(user_clubs: { club_sub_category_id: club_id }).where("DATE(user_clubs.created_at) <= ?", end_date.to_date) if end_date.present?

    users.distinct
  end

  def club_user(club_id)
    User.joins(club_sub_categories: :club_category).where("club_category_id = ?", club_id)
  end
end
