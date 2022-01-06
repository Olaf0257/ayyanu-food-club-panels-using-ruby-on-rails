class ChangeUserPrivilegeColumns < ActiveRecord::Migration[5.2]
  def change
    change_column :user_privileges, :fc, :text
    change_column :user_privileges, :pos, :text
    change_column :user_privileges, :pos_order_tracking, :text
    change_column :user_privileges, :pos_other_pages, :text
    change_column :user_privileges, :hrms, :text
    change_column :user_privileges, :task_management, :text
    change_column :user_privileges, :masters, :text
    change_column :user_privileges, :training, :text

    change_column :user_privileges, :document_scan, :text
    change_column :user_privileges, :reports, :text
    change_column :user_privileges, :enterprise, :text
  end
end
