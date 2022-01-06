class PostCategory < ApplicationRecord
  has_many :posts, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
end
