class CreateCashSpotChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_spot_checks do |t|
      t.integer :user_id
      t.datetime :date_of_descripency
      t.decimal :total_amount
      t.decimal :toal_cash_count
      t.string :currencies
      t.integer :restaurant_id

      t.timestamps
    end
  end
end
