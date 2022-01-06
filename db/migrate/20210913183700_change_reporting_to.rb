class ChangeReportingTo < ActiveRecord::Migration[5.2]
  def change
    change_column :user_details, :reporting_to, :integer
  end
end
