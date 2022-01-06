class CreateReferrals < ActiveRecord::Migration[5.1]
  def change
    create_table :referrals do |t|
      t.string :email
      t.boolean :is_registered
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
