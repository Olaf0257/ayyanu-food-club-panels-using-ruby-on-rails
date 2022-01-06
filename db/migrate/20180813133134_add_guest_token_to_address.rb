class AddGuestTokenToAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :guest_token, :string
  end
end
