class AddCoverageAreaToCart < ActiveRecord::Migration[5.1]
  def change
    add_reference :carts, :coverage_area, foreign_key: true
  end
end
