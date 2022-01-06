class AddTitleArToClubCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :club_categories, :title_ar, :string
    add_column :club_categories, :description_ar, :string
  end
end
