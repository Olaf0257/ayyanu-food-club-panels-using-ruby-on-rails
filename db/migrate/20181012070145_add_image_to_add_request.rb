class AddImageToAddRequest < ActiveRecord::Migration[5.1]
  def change
    add_column :add_requests, :image, :string
  end
end
