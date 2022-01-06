class AddColumnIsFullDiscountToPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :is_full_discount, :boolean, default: false
  end
end
