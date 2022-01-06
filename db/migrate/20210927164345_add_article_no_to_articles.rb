class AddArticleNoToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :article_no, :integer, index: true
  end
end
