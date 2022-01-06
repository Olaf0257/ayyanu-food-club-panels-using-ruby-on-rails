class AddStatusToReceiveArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :receive_articles, :status, :integer, default: 0
  end
end
