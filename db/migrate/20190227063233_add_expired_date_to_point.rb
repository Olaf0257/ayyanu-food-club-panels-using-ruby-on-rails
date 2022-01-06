class AddExpiredDateToPoint < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :expired_date, :datetime
  end
end
