class CreateUserPrivileges < ActiveRecord::Migration[5.2]
  def change
    create_table :user_privileges do |t|
      t.string :country_ids
      t.string :branch_ids
      t.string :department_ids
      t.string :designation_ids
      t.string :fc
      t.string :pos
      t.string :pos_order_tracking
      t.string :pos_other_pages
      t.string :hrms
      t.string :mc
      t.string :kds
      t.string :task_management
      t.string :masters
      t.string :training
      t.string :document_scan
      t.string :reports
      t.string :enterprise
      t.timestamps
    end
  end
end
