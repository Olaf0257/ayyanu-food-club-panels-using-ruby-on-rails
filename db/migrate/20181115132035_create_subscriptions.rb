class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions do |t|
      t.references :restaurant, foreign_key: true
      t.string :subscribe_date

      t.timestamps
    end
  end
end
