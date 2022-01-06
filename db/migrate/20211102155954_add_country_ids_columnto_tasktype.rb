class AddCountryIdsColumntoTasktype < ActiveRecord::Migration[5.2]
  def change

    add_column :task_types, :country_ids, :string
    remove_column :task_types , :country_id

    add_column :task_categories, :country_ids, :string
    remove_column :task_categories , :country_id

    add_column :task_lists, :country_ids, :string
    remove_column :task_lists , :country_id

    add_column :task_activities, :country_ids, :string
    remove_column :task_activities , :country_id
    
  end
end
