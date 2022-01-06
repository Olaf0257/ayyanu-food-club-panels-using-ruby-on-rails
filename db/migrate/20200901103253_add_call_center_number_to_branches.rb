class AddCallCenterNumberToBranches < ActiveRecord::Migration[5.2]
  def change
    remove_column :delivery_charges, :call_center_number, :string
    add_column :branches, :call_center_number, :string
  end
end
