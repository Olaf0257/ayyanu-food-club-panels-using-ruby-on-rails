class AddColumnsToWeeksTable < ActiveRecord::Migration[5.1]
  def change
    add_column :weeks, :country_id, :integer
  end
end
