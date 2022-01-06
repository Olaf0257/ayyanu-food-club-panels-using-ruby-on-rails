class AddCprNumberToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :cpr_number, :string
  end
end
