class ChangeDateInAddRequest < ActiveRecord::Migration[5.1]
  def change
  	change_column :weeks, :start_date, :date
  	change_column :weeks, :end_date, :date
  	change_column :advertisements, :from_date, :date
  	change_column :advertisements, :to_date, :date
  end
end
