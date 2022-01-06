module Api::V1::ClubesHelper
  def club_sub_category_json(category, language)
    category.as_json(logdinUser: @user, language: language)
  end

  def get_club_categories(page, per_page)
    ClubCategory.find_all_club_category(page, per_page)
  end

  def get_club_category(category_id)
    ClubCategory.find_category(category_id)
  end

  def get_club_sub_category(sub_category_id)
    ClubSubCategory.find_sub_category(sub_category_id)
  end

  def add_user_club(user, sub_category)
    UserClub.new_club_add(user, sub_category)
  end

  def get_user_club_info(sub_category, user)
    UserClub.find_user_club_data(sub_category, user)
  end
end
