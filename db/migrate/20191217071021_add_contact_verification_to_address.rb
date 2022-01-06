class AddContactVerificationToAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :contact_verification, :boolean,default: false
  end
end
