class AddIsActiveToOffers < ActiveRecord::Migration[5.1]
  def change
    add_column :offers, :is_active, :boolean,default: true
  end
end
