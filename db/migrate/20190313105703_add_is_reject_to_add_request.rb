class AddIsRejectToAddRequest < ActiveRecord::Migration[5.1]
  def change
    add_column :add_requests, :is_reject, :boolean,default: false
  end
end
