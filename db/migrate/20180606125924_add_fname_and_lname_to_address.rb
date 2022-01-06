class AddFnameAndLnameToAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :fname, :string
    add_column :addresses, :lname, :string
  end
end
