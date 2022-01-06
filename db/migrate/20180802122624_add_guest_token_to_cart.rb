class AddGuestTokenToCart < ActiveRecord::Migration[5.1]
  def change
    add_column :carts, :guest_token, :string
  end
end
