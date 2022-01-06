class AddQrImageToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :qr_image, :string
  end
end
