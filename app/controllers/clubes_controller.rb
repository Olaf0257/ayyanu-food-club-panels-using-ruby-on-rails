class ClubesController < ApplicationController
  before_action :require_admin_logged_in

  def club_list
    @clubes = ClubCategory.includes(:club_sub_categories)
    @clubes = @clubes.joins(:club_sub_categories).where("club_categories.title like ? OR club_sub_categories.title like ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%").distinct if params[:keyword].present?

    respond_to do |format|
      format.html do
        @clubes = @clubes.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      end

      format.csv { send_data @clubes.club_list_csv, filename: "club_list.csv" }
    end
  end

  def add_club_sub_category
    sub_category = find_sub_category(params[:club_sub_title])
    if !sub_category
      club_sub_category_add(params[:club_id], params[:club_sub_title], params[:club_sub_title_ar])
      flash[:success] = "Sub category added successfully."
      redirect_to club_list_path
    else
      flash[:error] = "Sub category exits!!"
      redirect_to club_list_path
    end
  end

  def add_club
    club = get_club(params[:club_title])
    if !club
      add_new_club(params[:club_title], params[:club_description], params[:club_image], params[:club_title_ar], params[:club_description_ar])
      flash[:success] = "Club added successfully."
      redirect_to club_list_path
    else
      flash[:error] = "Club exits!!"
      redirect_to club_list_path
    end
  end

  def club_sub_category
    @category = get_club_category(decode_token(params[:category_id]))

    if @category.present?
      @sub_category = @category.club_sub_categories
      @sub_category = @sub_category.where("club_sub_categories.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?

      respond_to do |format|
        format.html do
          @sub_category = @sub_category.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "admin_application"
        end

        format.csv { send_data @sub_category.sub_category_list_csv, filename: "sub_category_list.csv" }
      end
    else
      flash[:error] = "Club exits!!"
      render layout: "admin_application"
    end
  end

  def club_user
    @club_category = ClubCategory.exists?(decode_token(params[:id])) ? ClubCategory.find(decode_token(params[:id])) : ClubSubCategory.find(decode_token(params[:id]))

    @users = get_club_users(decode_token(params[:id]), params[:page], params[:per_page], @club_category, params[:keyword], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @users = @users.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      end

      format.csv { send_data @users.club_user_list_csv(@club_category), filename: "club_user_list.csv" }
    end
  end

  def edit_sub_category
    sub_category_title = find_sub_category(params[:club_sub_title])
    club_sub_category = find_club_sub_category(params[:sub_club_id])
    if club_sub_category.present?
      club_sub_category.update(title: params[:club_sub_title], title_ar: params[:club_sub_title_ar])
      flash[:success] = "Club sub category update successfully."
    else
      flash[:error] = "Club sub category exits!!"
    end
    redirect_to club_sub_category_path(encode_token(params[:club_id]))
  end

  def edit_club_category
    @category = get_club_category(params[:club_category_id])

    if @category.present?
      prev_img = @category.img_url.present? ? @category.img_url.split("/").last : "n/a"
      image = params[:club_image].present? ? update_multipart_image(prev_img, params[:club_image], "club_image") : @category.img_url
      @category.update(title: params[:club_title], description: params[:club_description], title_ar: params[:club_title_ar], description_ar: params[:club_description_ar], img_url: image)
      flash[:success] = "Club category update successfully."
    else
      flash[:error] = "Club category exits!!"
    end

    redirect_to club_list_path
  end
end
