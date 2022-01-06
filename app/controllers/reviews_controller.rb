class ReviewsController < ApplicationController
  before_action :require_admin_logged_in

  def review_list
    @reviews = get_review
    render layout: "admin_application"
  end

  def add_review_category
    review = get_review_data(params[:review_for], params[:vote_type])
    if review.count < 4
      review = add_new_review(params[:review_for], params[:review_category])
      flash[:success] = "Review added successfully."
      redirect_to review_list_path
    else
      flash[:error] = "Review can not added more than of 4."
      redirect_to review_list_path
    end
  end
end
