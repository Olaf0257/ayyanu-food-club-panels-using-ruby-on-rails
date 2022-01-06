class AddPictureToAssignAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_assets, :picture, :string
    add_column :assign_assets, :lost_on, :date
    add_column :assign_assets, :issue_on, :date
  end
end
