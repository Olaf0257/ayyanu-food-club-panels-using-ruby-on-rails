class AddFieldsToReceiveArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :receive_articles, :gift_quantity, :integer
    add_column :receive_articles, :discount, :float
    add_column :receive_articles, :stock, :integer
  end
end
