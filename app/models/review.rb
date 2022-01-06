class Review < ApplicationRecord
  def self.create_review(review_for, _vote_type, review_category)
    create(review_type: review_category, review_for: review_for)
  end
end
