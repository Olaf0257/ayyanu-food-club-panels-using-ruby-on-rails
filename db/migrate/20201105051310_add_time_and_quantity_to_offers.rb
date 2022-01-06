class AddTimeAndQuantityToOffers < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :start_time, :datetime
    add_column :offers, :end_time, :datetime
    add_column :offers, :limited_quantity, :boolean, null: false, default: false
    add_column :offers, :quantity, :integer
  end
end
