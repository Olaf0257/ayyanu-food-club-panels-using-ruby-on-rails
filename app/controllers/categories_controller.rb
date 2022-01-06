class CategoriesController < ApplicationController
  before_action :require_admin_logged_in

  def categories_list
    @categories = get_all_categories(params[:keyword], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @categories = @categories.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      end

      format.csv { send_data @categories.category_list_csv, filename: "cuisine_list.csv" }
    end
  end

  def add_category
    category = Category.find_by(title: params[:name])

    if category.blank?
      image = upload_multipart_image(params[:category_image], "categories") if params[:category_image].present?

      if @admin.class.name == "SuperAdmin"
        @category = Category.create(title: params[:name], icon: image, title_ar: params[:title_ar])
      else
        country_id = @admin.class.find(@admin.id)[:country_id]
        @category = Category.create(title: params[:name], icon: image, title_ar: params[:title_ar], country_id: country_id)
      end

      flash[:success] = "successfully created"
    else
      flash[:error] = "Already exists"
    end
    redirect_to categories_list_path
  end

  def update_category
    category = Category.find_by(id: params[:category_id])

    if category
      prev_img = category.icon.present? ? category.icon.split("/").last : "n/a"
      url = params[:category_image].present? ? update_multipart_image(prev_img, params[:category_image], "categories") : category.icon

      if @admin.class.name == "SuperAdmin"
        category.update(title: params[:name], icon: url, title_ar: params[:name_ar])
      else
        country_id = @admin.class.find(@admin.id)[:country_id]
        category.update(title: params[:name], icon: url, title_ar: params[:name_ar], country_id: country_id)
      end

      flash[:success] = "successfully update"
    else
      flash[:error] = "Category not exists"
    end
    redirect_to categories_list_path
  end

  def remove_category
    category = Category.find_by(id: params[:category_id])

    if category.present?
      remove_multipart_image(category.icon.split("/").last, "categories") if category.icon.present?
      category.destroy
      send_json_response("Category remove", "success", {})
    else
      send_json_response("Category", "not exist", {})
    end
  end

  def restaurant_list
    @category = Category.find(params[:category_id])
    @restaurants = Restaurant.where(id: @category.branches.pluck(:restaurant_id).uniq).order(:title)

    respond_to do |format|
      format.js { @restaurants }
      format.csv { send_data @restaurants.cuisine_restaurants_list_csv(@category), filename: "Cuisine Restaurant List.csv" }
    end
  end
end
