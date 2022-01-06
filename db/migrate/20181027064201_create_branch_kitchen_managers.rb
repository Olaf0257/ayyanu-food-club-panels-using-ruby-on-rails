class CreateBranchKitchenManagers < ActiveRecord::Migration[5.1]
  def change
    create_table :branch_kitchen_managers do |t|
      t.references :user, foreign_key: true
      t.references :branch, foreign_key: true

      t.timestamps
    end
  end
end
