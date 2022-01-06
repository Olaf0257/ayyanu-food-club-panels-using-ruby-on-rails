class AddColumnLimitToOffer < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :limit, :integer
    add_column :admin_offers, :limit, :integer
    add_reference :pos_checks, :offer
  end
end
