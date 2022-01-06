class CreatePoints < ActiveRecord::Migration[5.1]
  def change
    create_table :points do |t|
      t.references :user, foreign_key: true
      t.references :order, foreign_key: true
      t.references :branch, foreign_key: true
      t.float :user_point

      t.timestamps
    end
  end
end
