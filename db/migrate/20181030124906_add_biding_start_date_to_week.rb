class AddBidingStartDateToWeek < ActiveRecord::Migration[5.1]
  def change
    add_column :weeks, :biding_start_date, :datetime
    add_column :weeks, :biding_end_date, :datetime
    add_column :weeks, :is_active, :boolean,default: false
  end
end
