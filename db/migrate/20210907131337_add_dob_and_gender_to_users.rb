class AddDobAndGenderToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :dob, :date
    add_column :users, :gender, :string
  end
end
