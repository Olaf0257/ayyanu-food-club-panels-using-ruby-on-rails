class ChangeDeliveryTimeInBranch < ActiveRecord::Migration[5.1]
  def change
  	change_column :branches, :delivery_time, :integer
  end
end
