class AddDefaultValueToWeeksTable < ActiveRecord::Migration[5.1]
  def change
    Week.where(country_id: nil).update_all(country_id: 15)
  end
end
