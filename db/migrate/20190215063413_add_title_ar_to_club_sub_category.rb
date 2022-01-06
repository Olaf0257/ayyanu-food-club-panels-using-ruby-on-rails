class AddTitleArToClubSubCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :club_sub_categories, :title_ar, :string
  end
end
