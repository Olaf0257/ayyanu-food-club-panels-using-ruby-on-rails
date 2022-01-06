class AddReceiveArticleToInventories < ActiveRecord::Migration[5.2]
  def change
    add_reference :inventories, :receive_article, foreign_key: true
  end
end
