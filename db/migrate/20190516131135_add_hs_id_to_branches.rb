class AddHsIdToBranches < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :hs_id, :integer
  end
end
