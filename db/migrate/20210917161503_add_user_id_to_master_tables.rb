class AddUserIdToMasterTables < ActiveRecord::Migration[5.2]
  def change
    add_reference :over_groups, :user, index: true
    add_reference :major_groups, :user, index: true
  end
end
