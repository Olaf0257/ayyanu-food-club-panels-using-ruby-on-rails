class CreateAppDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :app_details do |t|
      t.text :ios_store_link
      t.string :ios_current_version
      t.boolean :ios_version_force_update, default: false
      t.text :android_store_link
      t.string :android_current_version
      t.boolean :android_version_force_update, default: false
      t.timestamps
    end
  end
end
