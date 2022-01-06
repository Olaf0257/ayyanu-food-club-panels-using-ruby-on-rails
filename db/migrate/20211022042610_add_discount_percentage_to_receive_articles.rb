class AddDiscountPercentageToReceiveArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :receive_articles, :discount_percentage, :float
    add_column :receive_articles, :vat_percentage, :float
    remove_column :receive_articles, :gift_quantity
  end
end
