class AddcolumnstoTakslist < ActiveRecord::Migration[5.2]
  def change
  	add_column :task_lists, :url, :string
  	add_column :task_lists, :enable, :boolean
  	add_column :task_lists, :task_sub_category_id, :integer , foreign_key: :true
  end
end
