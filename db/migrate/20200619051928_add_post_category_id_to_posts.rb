class AddPostCategoryIdToPosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :post_category, foreign_key: true, index: true
  end
end
