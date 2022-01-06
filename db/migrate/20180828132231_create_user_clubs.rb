class CreateUserClubs < ActiveRecord::Migration[5.1]
  def change
    create_table :user_clubs do |t|
      t.references :user, foreign_key: true
      t.references :club_sub_category, foreign_key: true

      t.timestamps
    end
  end
end
