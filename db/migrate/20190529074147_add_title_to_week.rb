class AddTitleToWeek < ActiveRecord::Migration[5.1]
  def change
    add_column :weeks, :title, :string
  end
end
