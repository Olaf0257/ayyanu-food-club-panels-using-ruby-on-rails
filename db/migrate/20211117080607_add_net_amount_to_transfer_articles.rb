class AddNetAmountToTransferArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :transfer_articles, :net_amount, :float
  end
end
