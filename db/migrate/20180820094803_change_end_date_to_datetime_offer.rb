class ChangeEndDateToDatetimeOffer < ActiveRecord::Migration[5.1]
  def change
  	change_column :offers, :start_date, :datetime
  	change_column :offers, :end_date, :datetime
  end
end
