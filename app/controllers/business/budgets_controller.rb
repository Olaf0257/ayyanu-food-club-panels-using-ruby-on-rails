class Business::BudgetsController < ApplicationController
  before_action :authenticate_business
  def budget_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      @branches = restaurant.branches
      @budgets = get_budget_list(@branches)
      render layout: "partner_application"
    else
      redirect_to_root
    end
  end

  def add_budget
    restaurant = params[:restaurant_id]
    branch = get_branch_data(params[:branch])
    if branch
      addBudget = add_new_budget(branch, params[:amount], params[:start_date], params[:end_date])
      flash[:success] = "Budget added sucessfully."
      redirect_to business_budget_list_path(restaurant_id: restaurant)
    else
      flash[:error] = "Invalid branch !!"
      redirect_to business_budget_list_path(restaurant_id: restaurant)
    end
  end
end
