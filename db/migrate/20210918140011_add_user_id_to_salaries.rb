class AddUserIdToSalaries < ActiveRecord::Migration[5.2]
  def change
    add_column :salaries, :user_id, :integer
  end
end
