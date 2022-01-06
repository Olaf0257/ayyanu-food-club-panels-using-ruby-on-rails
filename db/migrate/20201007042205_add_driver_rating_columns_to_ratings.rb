class AddDriverRatingColumnsToRatings < ActiveRecord::Migration[5.2]
  def change
    remove_column :ratings, :packaging_rating, :string
    remove_column :ratings, :value_rating, :string
    remove_column :ratings, :delivery_time_rating, :string
    remove_column :ratings, :food_quality_rating, :string
    remove_column :ratings, :driver_rating, :string
    add_column :ratings, :food_quantity_rating, :string, null: false, default: ""
    add_column :ratings, :food_taste_rating, :string, null: false, default: ""
    add_column :ratings, :value_rating, :string, null: false, default: ""
    add_column :ratings, :packaging_rating, :string, null: false, default: ""
    add_column :ratings, :seal_rating, :string, null: false, default: ""
    add_column :ratings, :delivery_time_rating, :string, null: false, default: ""
    add_column :ratings, :clean_uniform_rating, :string, null: false, default: ""
    add_column :ratings, :polite_rating, :string, null: false, default: ""
    add_column :ratings, :distance_rating, :string, null: false, default: ""
    add_column :ratings, :mask_rating, :string, null: false, default: ""
    add_column :ratings, :driver_rating, :string, null: false, default: ""
    add_column :ratings, :driver_comments, :string, null: false, default: ""
  end
end
