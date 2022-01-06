class AddAvgRatingToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :avg_rating, :float,default: 0.0
  end
end
