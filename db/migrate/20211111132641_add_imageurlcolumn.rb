class AddImageurlcolumn < ActiveRecord::Migration[5.2]
  def change
  	add_column :employee_assign_tasks, :image_url, :string
  end
end
