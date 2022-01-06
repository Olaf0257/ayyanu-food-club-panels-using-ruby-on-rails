class Business::CategoriesController < ApplicationController
  before_action :authenticate_business
  def category_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      @branch = get_branch_data(decode_token(params[:id]))
      @branches = restaurant.branches
      if @branch
        @cuisine = @branch.branch_categories.paginate(page: params[:page], per_page: params[:per_page])
        @categories = Category.all
      else
        flash[:error] = "Invalid!!"
      end
      render layout: "partner_application"
    else
      @branch = get_branch_data(decode_token(params[:id]))
      @branches = @branch.restaurant.branches
      if @branch
        @cuisine = @branch.branch_categories.paginate(page: params[:page], per_page: params[:per_page])
        @categories = Category.all
      else
        flash[:error] = "Invalid!!"
      end
      render layout: "partner_application"
    end

    rescue Exception => e
  end

  def add_branch_category
    @branch = get_branch_data(params[:branch_id])
    if @branch
      branch_categories = get_branch_categories(@branch, params[:category_id])
      if branch_categories.blank?
        @branch.branch_categories.create(category_id: params[:category_id])
        flash[:success] = "Cuisine added sucessfully!!"
      else
        flash[:error] = "Cuisine already added!!"
      end
    else
      flash[:error] = "Invalid!!"
    end
    redirect_to business_cuisine_list_path(id: encode_token(@branch.id), restaurant_id: params[:restaurant_id])
    rescue Exception => e
  end

  def remove_branch_category
    branch_categories = get_branch_categories_data(params[:category_id])
    if branch_categories.present?
      branch_categories.destroy
      send_json_response("Category remove", "success", {})
    else
      send_json_response("Category", "not exist", {})
    end

    rescue Exception => e
  end
end
