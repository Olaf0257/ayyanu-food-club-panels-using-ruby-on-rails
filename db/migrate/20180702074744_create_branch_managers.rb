class CreateBranchManagers < ActiveRecord::Migration[5.1]
  def change
    create_table :branch_managers do |t|
      t.references :branch, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
