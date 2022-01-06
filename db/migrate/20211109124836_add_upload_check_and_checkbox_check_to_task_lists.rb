class AddUploadCheckAndCheckboxCheckToTaskLists < ActiveRecord::Migration[5.2]
  def change
    add_column :task_lists, :upload_check, :boolean, default: false
    add_column :task_lists, :checkbox_check, :boolean, default: false
    add_column :task_lists, :is_completed, :boolean, default: false
  end
end
