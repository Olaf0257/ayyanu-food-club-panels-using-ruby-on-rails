class Api::V1::ClubesController < Api::ApiController
  before_action :authenticate_guest_access

  def club_category_list
    categories = get_club_categories(params[:page], params[:per_page])
    responce_json(code: 200, message: "Club data.", categories: categories.as_json(language: request.headers["language"]))
  end

  def clube_sub_category_list
    category = get_club_category(params[:category_id])
    if category
      responce_json(code: 200, message: "Club data.", sub_categories: club_sub_category_json(category.club_sub_categories, request.headers["language"]))
    else
      responce_json(code: 404, message: "Category not found!!")
    end
  end

  def user_club
    subCategory = get_club_sub_category(params[:sub_category_id])
    if subCategory
      userClub = get_user_club_info(subCategory, @user)
      if !userClub
        userClub = add_user_club(@user, subCategory)
        data = {}
        data["id"] = userClub[:result].id
        data["club_sub_category_id"] = userClub[:result].club_sub_category_id
        data["status"] = true
        responce_json(code: 200, message: "Club data added successfully.", club: data)
      else
        userClub.destroy
        responce_json(code: 422, message: "Remove club !!")
      end
    else
      responce_json(code: 404, message: "category not added!!")
    end

    rescue Exception => e
  end
end
