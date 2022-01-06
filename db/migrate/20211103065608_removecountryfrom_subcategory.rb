class RemovecountryfromSubcategory < ActiveRecord::Migration[5.2]
  def change
  	add_column :task_sub_categories, :country_ids, :string
    remove_column :task_sub_categories , :country_id

    add_column :job_positions, :country_ids, :string
    remove_column :job_positions , :country_id , :integer
  end
end
