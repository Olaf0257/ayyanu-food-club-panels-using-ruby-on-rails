class AddCoverageAreaIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :coverage_area, foreign_key: true
  end
end
