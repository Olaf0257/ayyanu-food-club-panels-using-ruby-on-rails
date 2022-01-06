class AddIndexToIous < ActiveRecord::Migration[5.1]
  def change
  	add_index :ious, :transporter_id
  end
end
