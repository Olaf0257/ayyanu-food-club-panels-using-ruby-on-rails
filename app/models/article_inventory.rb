class ArticleInventory < ApplicationRecord
  belongs_to :article
  belongs_to :restaurant
  belongs_to :user
end
