class AddAddressArToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :address_ar, :string
  end
end
