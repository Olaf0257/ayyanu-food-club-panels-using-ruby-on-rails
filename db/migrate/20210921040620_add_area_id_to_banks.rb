class AddAreaIdToBanks < ActiveRecord::Migration[5.2]
  def change
    add_column :banks, :area_id, :integer
  end
end
