class AddLocationToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :location, :string
  end
end
