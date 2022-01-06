class AddPartyPointToPoints < ActiveRecord::Migration[5.2]
  def change
    add_column :points, :party_point, :float, null: false, default: 0
  end
end
