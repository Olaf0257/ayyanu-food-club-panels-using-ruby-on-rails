class DeleteMultiDebitPoints < ActiveRecord::Migration[5.2]
  def up
    points = Point.debited.joins(:order).group(:order_id).having("count(order_id) > 1").count(:order_id)

    points.each do |key, value|
      duplicates = Point.where(order_id: key)[1..value-1]
      duplicates.each(&:destroy)
    end
  end

  def down
  end
end
