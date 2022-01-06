class CreateDeliveryCompanyAndZonesJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_companies_zones, id: false do |t|
      t.belongs_to :delivery_company, index: true, null: false
      t.belongs_to :zone, index: true, null: false

      t.timestamps
    end
  end
end
