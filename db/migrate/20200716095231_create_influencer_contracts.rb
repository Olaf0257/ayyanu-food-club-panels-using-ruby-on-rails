class CreateInfluencerContracts < ActiveRecord::Migration[5.2]
  def change
    create_table :influencer_contracts do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
