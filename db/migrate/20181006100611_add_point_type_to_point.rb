class AddPointTypeToPoint < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :point_type, :string
  end
end
