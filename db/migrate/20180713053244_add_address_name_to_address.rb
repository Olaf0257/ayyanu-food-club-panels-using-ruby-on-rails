class AddAddressNameToAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :address_name, :string
  end
end
