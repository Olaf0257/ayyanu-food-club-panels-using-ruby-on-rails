class AddScheduleCheckToPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :is_scheduled_check, :boolean, default: false
  end
end
