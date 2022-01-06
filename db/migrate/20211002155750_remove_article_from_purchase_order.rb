class RemoveArticleFromPurchaseOrder < ActiveRecord::Migration[5.2]
  def change
    remove_reference :purchase_orders, :article, foreign_key: true
  end
end
