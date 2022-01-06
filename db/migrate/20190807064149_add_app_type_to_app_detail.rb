class AddAppTypeToAppDetail < ActiveRecord::Migration[5.1]
  def change
    add_column :app_details, :app_type, :string
    add_index :app_details, :app_type
  end
end
