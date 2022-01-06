class AddImgUrlToClubCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :club_categories, :img_url, :string
    add_column :club_categories, :description, :text
  end
end
