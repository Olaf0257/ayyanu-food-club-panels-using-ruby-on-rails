class CreateCoverageAreas < ActiveRecord::Migration[5.1]
  def change
    create_table :coverage_areas do |t|
      t.string :area
      t.references :city, foreign_key: true

      t.timestamps
    end
  end
end
