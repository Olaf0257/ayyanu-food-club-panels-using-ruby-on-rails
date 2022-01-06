class CreateAdminOffers < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_offers do |t|
      t.string :offer_title, null: false
      t.string :offer_percentage
      t.string :offer_image
      t.references :country, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
