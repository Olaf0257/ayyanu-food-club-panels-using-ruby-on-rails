class AddSubTotalToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :sub_total, :float,default: "0.000"
  end
end
