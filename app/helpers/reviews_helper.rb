module ReviewsHelper
  def get_review
    Review.all.paginate(page: params[:page], per_page: params[:per_page])
  end

  def get_review_data(review_for, vote_type)
    Review.where("review_for = ? and vote_type = ?", review_for, vote_type)
  end

  def add_new_review(review_for, review_category)
    Review.create_review(review_for, review_category)
  end
end
