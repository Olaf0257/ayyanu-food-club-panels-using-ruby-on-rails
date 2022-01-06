class CreateOffers < ActiveRecord::Migration[5.1]
  def change
    create_table :offers do |t|
      t.string :offer_type
      t.string :discount_percentage
      t.string :start_date
      t.string :end_date
      t.string :offer_title
      t.references :branch, foreign_key: true
      t.references :menu_item, foreign_key: true

      t.timestamps
    end
  end
end
