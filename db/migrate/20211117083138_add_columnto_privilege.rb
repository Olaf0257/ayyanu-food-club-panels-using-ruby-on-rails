class AddColumntoPrivilege < ActiveRecord::Migration[5.2]
  def change
  	 add_column :user_privileges,  :created_by_id , :integer
  end
end
