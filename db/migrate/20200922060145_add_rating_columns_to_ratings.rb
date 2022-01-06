class AddRatingColumnsToRatings < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings, :packaging_rating, :string, null: false, default: ""
    add_column :ratings, :value_rating, :string, null: false, default: ""
    add_column :ratings, :delivery_time_rating, :string, null: false, default: ""
    add_column :ratings, :food_quality_rating, :string, null: false, default: ""
    add_column :ratings, :driver_rating, :string, null: false, default: ""
  end
end
