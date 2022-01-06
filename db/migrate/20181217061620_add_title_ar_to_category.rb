class AddTitleArToCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :categories, :title_ar, :string
  end
end
