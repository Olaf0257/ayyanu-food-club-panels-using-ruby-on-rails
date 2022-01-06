class Post < ApplicationRecord
  USER_TYPES = { 1 => "Admin", 2 => "Business", 3 => "Delivery Company", 4 => "Influencer", 5 => "Website", 6 => "Call Center" }.freeze
  USER_TYPE_LIST = [["Admin", 1], ["Business", 2], ["Delivery Company", 3], ["Influencer", 4], ["Website", 5], ["Call Center", 6]].freeze

  belongs_to :post_category, optional: true

  validates :title, :body, :user_type, presence: true

  scope :filter_by_user_type, ->(user_type)   { where(user_type: user_type) }
  scope :filter_by_category,  ->(category_id) { where(post_category_id: category_id) }
  scope :search_by_keyword,   ->(keyword)     { where("title like ? OR body like ?", "%#{keyword}%", "%#{keyword}%") }
end
